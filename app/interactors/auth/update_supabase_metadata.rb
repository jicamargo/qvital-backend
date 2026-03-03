require 'net/http'
require 'net/https'
require 'json'
require 'openssl'

module Auth
  class UpdateSupabaseMetadata
    attr_reader :error

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
      @error = nil
    end

    def call
      return failure('User is required') unless @user
      return failure('User must have supabase_uid') unless @user.supabase_uid.present?
      return failure('SUPABASE_URL is not set') unless supabase_url.present?
      return failure('SUPABASE_SERVICE_ROLE_KEY is not set') unless service_role_key.present?

      update_user_metadata
      self
    rescue StandardError => e
      @error = "Failed to update Supabase metadata: #{e.message}"
      Rails.logger.error "Supabase metadata update error: #{@error}"
      Rails.logger.error e.backtrace.join("\n")
      self
    end

    def success?
      @error.nil?
    end

    private

    def update_user_metadata
      url = URI("#{supabase_url}/auth/v1/admin/users/#{@user.supabase_uid}")
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.read_timeout = 10
      http.open_timeout = 10

      request = Net::HTTP::Put.new(url)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{service_role_key}"
      request['apikey'] = service_role_key

      # Actualizar app_metadata con el role del usuario
      # app_metadata es más seguro porque no puede ser modificado por el cliente
      body = {
        app_metadata: {
          role: @user.role
        }
      }

      request.body = body.to_json

      Rails.logger.info "Updating Supabase app_metadata for user #{@user.supabase_uid} with role: #{@user.role}"

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        error_message = "HTTP #{response.code}: #{response.message}"
        begin
          error_body = JSON.parse(response.body)
          error_message = error_body['message'] || error_body['error_description'] || error_message
        rescue JSON::ParserError
          # Si no se puede parsear, usar el mensaje por defecto
        end
        raise StandardError, error_message
      end

      Rails.logger.info "Successfully updated Supabase app_metadata for user #{@user.supabase_uid}"
    end

    def supabase_url
      url = ENV['SUPABASE_URL']
      return nil unless url

      # Asegurar que la URL tenga el protocolo https://
      url = "https://#{url}" unless url.start_with?('http://', 'https://')
      # Remover trailing slash si existe
      url.chomp('/')
    end

    def service_role_key
      ENV['SUPABASE_SERVICE_ROLE_KEY']
    end

    def failure(message)
      @error = message
      self
    end
  end
end
