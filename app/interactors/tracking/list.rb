module Tracking
  class List
    attr_reader :entries, :error

    def self.call(user:)
      new(user:).call
    end

    def initialize(user:)
      @user = user
      @entries = []
      @error = nil
    end

    def call
      return failure("User is required") unless @user

      @entries = @user.tracking_entries.most_recent_first
      self
    rescue StandardError => e
      @error = "Error listing tracking entries: #{e.message}"
      self
    end

    def success?
      @error.nil?
    end

    private

    def failure(message)
      @error = message
      self
    end
  end
end
