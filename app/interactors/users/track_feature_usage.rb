module Users
  class TrackFeatureUsage
    attr_reader :usage, :error

    def self.call(user:, feature_key:)
      new(user:, feature_key:).call
    end

    def initialize(user:, feature_key:)
      @user = user
      @feature_key = feature_key
      @error = nil
    end

    def call
      return failure('User is required') unless @user
      return failure('feature_key is required') unless @feature_key.present?
      unless UserFeatureUsage::FEATURE_KEYS.include?(@feature_key)
        return failure("Invalid feature_key: #{@feature_key}")
      end

      upsert!
      self
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence)
    rescue StandardError => e
      Rails.logger.error "Error tracking feature usage: #{e.class.name} - #{e.message}"
      failure('Unexpected error tracking feature usage')
    end

    def success?
      @error.nil?
    end

    private

    # Upsert atómico a nivel de base de datos (ON CONFLICT) para no perder
    # incrementos de use_count bajo requests concurrentes del mismo usuario.
    def upsert!
      now = Time.current
      UserFeatureUsage.upsert(
        { user_id: @user.id, feature_key: @feature_key, last_used_at: now, use_count: 1, created_at: now, updated_at: now },
        unique_by: [:user_id, :feature_key],
        on_duplicate: Arel.sql("use_count = user_feature_usages.use_count + 1, last_used_at = EXCLUDED.last_used_at, updated_at = EXCLUDED.updated_at")
      )
      @usage = @user.user_feature_usages.find_by(feature_key: @feature_key)
    end

    def failure(message)
      @error = message
      self
    end
  end
end
