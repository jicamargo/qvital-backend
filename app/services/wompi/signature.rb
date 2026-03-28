require "digest"

module Wompi
  module Signature
    module_function

    def checkout_integrity(reference:, amount_in_cents:, currency:, expiration_time: nil)
      secret = Config.integrity_secret
      raise "WOMPI_INTEGRITY_SECRET is not configured" if secret.blank?

      payload = "#{reference}#{amount_in_cents}#{currency}"
      payload += expiration_time.to_s if expiration_time.present?
      payload += secret

      Digest::SHA256.hexdigest(payload)
    end

    def valid_webhook_checksum?(payload:, header_checksum: nil)
      signature = payload["signature"] || {}
      checksum = (header_checksum.presence || signature["checksum"]).to_s
      return false if checksum.blank?

      properties = Array(signature["properties"])
      timestamp = payload["timestamp"]
      return false if properties.empty? || timestamp.blank?

      secret = Config.events_secret
      return false if secret.blank?

      data = payload["data"] || {}
      concatenated_values = properties.map { |path| extract_value(data, path) }.join
      calculated = Digest::SHA256.hexdigest("#{concatenated_values}#{timestamp}#{secret}")

      ActiveSupport::SecurityUtils.secure_compare(calculated.downcase, checksum.downcase)
    rescue StandardError
      false
    end

    def extract_value(source, dotted_path)
      dotted_path.to_s.split(".").reduce(source) do |acc, key|
        break nil unless acc.is_a?(Hash)

        acc[key]
      end.to_s
    end
  end
end
