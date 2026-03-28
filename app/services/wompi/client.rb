require "net/http"
require "json"

module Wompi
  class Client
    def self.fetch_transaction(transaction_id:)
      new.fetch_transaction(transaction_id:)
    end

    def fetch_transaction(transaction_id:)
      url = URI("#{Wompi::Config.api_base_url}/transactions/#{transaction_id}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 10

      request = Net::HTTP::Get.new(url)
      request["Authorization"] = "Bearer #{Wompi::Config.private_key}" if Wompi::Config.private_key.present?

      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      body["data"]
    rescue StandardError => e
      Rails.logger.warn "Wompi transaction fetch failed: #{e.class.name} - #{e.message}"
      nil
    end
  end
end
