module Admin
  module Settings
    class Update
      attr_reader :setting, :error, :errors

      def self.call(params:)
        new(params: params).call
      end

      def initialize(params:)
        @params = params || {}
        @setting = nil
        @error = nil
        @errors = {}
      end

      def call
        @setting = AppSetting.current

        unless @setting.update(setting_attributes)
          @errors = @setting.errors.to_hash
        end

        self
      rescue StandardError => e
        @error = "Error updating settings: #{e.message}"
        self
      end

      def success?
        @error.nil? && @errors.empty?
      end

      private

      def setting_attributes
        @params.slice(:premium_purchase_threshold)
      end
    end
  end
end
