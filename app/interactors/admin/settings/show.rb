module Admin
  module Settings
    class Show
      attr_reader :setting, :error

      def self.call
        new.call
      end

      def call
        @setting = AppSetting.current
        self
      rescue StandardError => e
        @error = "Error loading settings: #{e.message}"
        self
      end

      def success?
        @error.nil?
      end
    end
  end
end
