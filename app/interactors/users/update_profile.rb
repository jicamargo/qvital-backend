module Users
  class UpdateProfile
    attr_reader :user, :error

    def self.call(user:, attributes:)
      new(user:, attributes:).call
    end

    def initialize(user:, attributes:)
      @user = user
      @attributes = (attributes || {}).to_h.with_indifferent_access
      @error = nil
    end

    def call
      return failure('User is required') unless @user

      @user.assign_attributes(permitted_attributes)
      @user.save!
      self
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence)
    rescue StandardError => e
      Rails.logger.error "Error updating user profile: #{e.class.name} - #{e.message}"
      failure('Unexpected error updating profile')
    end

    def success?
      @error.nil?
    end

    private

    def permitted_attributes
      @attributes.slice(:name, :last_name, :phone, :address).compact
    end

    def failure(message)
      @error = message
      self
    end
  end
end
