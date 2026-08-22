require "net/http"
require "json"
require "cgi"

module Wompi
  class Client
    def self.fetch_transaction(transaction_id:)
      new.fetch_transaction(transaction_id:)
    end

    def self.fetch_transactions_by_reference(reference:)
      new.fetch_transactions_by_reference(reference:)
    end

    def fetch_transaction(transaction_id:)
      url = URI("#{Wompi::Config.api_base_url}/transactions/#{transaction_id}")
      body = get(url)
      body && body["data"]
    end

    # Busca todas las transacciones creadas con una referencia (reference) dada.
    # Útil para reconciliación manual desde admin, cuando aún no conocemos el id
    # de transacción de Wompi (p. ej. el webhook nunca llegó).
    def fetch_transactions_by_reference(reference:)
      url = URI("#{Wompi::Config.api_base_url}/transactions?reference=#{CGI.escape(reference.to_s)}")
      body = get(url)
      return [] unless body

      Array(body["data"])
    end

    private

    def get(url)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 10

      request = Net::HTTP::Get.new(url)
      request["Authorization"] = "Bearer #{Wompi::Config.private_key}" if Wompi::Config.private_key.present?

      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.warn "Wompi API request failed: #{e.class.name} - #{e.message}"
      nil
    end
  end
end
