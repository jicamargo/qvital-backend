require 'jwt'
require 'net/http'
require 'net/https'
require 'json'
require 'openssl'

module Auth
  class SyncUser
    attr_reader :user, :error

    def self.call(token:)
      new(token: token).call
    end

    def initialize(token:)
      @token = token
      @error = nil
      @user = nil
    end

    def call
      return failure('No token provided') if @token.blank?

      decoded_payload = validate_and_decode_token
      return failure(@error) unless decoded_payload

      sync_user(decoded_payload)
      self
    end

    def success?
      @error.nil? && @user.present?
    end

    private

    def validate_and_decode_token
      jwks = fetch_jwks
      return nil unless jwks

      decoded = JWT.decode(
        @token,
        nil, # No se usa secret, se usa JWKS
        true, # Verificar firma
        algorithms: ['ES256'], # Algoritmo ECC P-256
        jwks: jwks
      )

      decoded.first
    rescue JWT::DecodeError => e
      @error = "Invalid token: #{e.message}"
      nil
    rescue StandardError => e
      @error = "Token validation error: #{e.message}"
      nil
    end

    def fetch_jwks
      supabase_url = ENV['SUPABASE_URL']
      unless supabase_url
        @error = "SUPABASE_URL environment variable is not set"
        return nil
      end

      # Asegurar que la URL tenga el protocolo https://
      supabase_url = "https://#{supabase_url}" unless supabase_url.start_with?('http://', 'https://')
      
      # Remover trailing slash si existe
      supabase_url = supabase_url.chomp('/')
      
      jwks_url = "#{supabase_url}/auth/v1/.well-known/jwks.json"
      url = URI(jwks_url)
      
      Rails.logger.info "Fetching JWKS from: #{jwks_url}"
      
      # Usar Net::HTTP con SSL para HTTPS
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.read_timeout = 10
      http.open_timeout = 10
      
      request = Net::HTTP::Get.new(url)
      response = http.request(request)
      
      unless response.is_a?(Net::HTTPSuccess)
        @error = "Failed to fetch JWKS: HTTP #{response.code} #{response.message}"
        Rails.logger.error "JWKS fetch failed: #{@error}"
        return nil
      end
      
      JSON.parse(response.body)
    rescue SocketError => e
      @error = "DNS resolution failed for #{url&.host || 'Supabase URL'}. Check your network connection and SUPABASE_URL: #{e.message}"
      Rails.logger.error "JWKS DNS error: #{@error}"
      nil
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      @error = "Connection timeout while fetching JWKS: #{e.message}"
      Rails.logger.error "JWKS timeout: #{@error}"
      nil
    rescue StandardError => e
      @error = "Failed to fetch JWKS: #{e.class.name} - #{e.message}"
      Rails.logger.error "JWKS error: #{@error}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    def sync_user(payload)
      supabase_uid = payload['sub']
      email = payload['email']

      return failure('Missing sub or email in token') unless supabase_uid && email

      @user = User.find_or_initialize_by(supabase_uid: supabase_uid)
      @user.email = email

      if @user.new_record?
        default_level = Level.find_by(name: 'Cliente')
        @user.level = default_level
        @user.role = 'cliente'
      end

      @user.save!

      # Actualizar metadata en Supabase con el role del usuario
      # Esto permite que supabase.auth.getUser() incluya el role en app_metadata
      update_supabase_metadata
    rescue ActiveRecord::RecordInvalid => e
      @error = "User validation failed: #{e.message}"
      @user = nil
    rescue StandardError => e
      @error = "User sync error: #{e.message}"
      @user = nil
    end

    def update_supabase_metadata
      return unless @user.persisted? && @user.supabase_uid.present?

      metadata_result = Auth::UpdateSupabaseMetadata.call(user: @user)
      
      unless metadata_result.success?
        # Log el error pero no fallar la sincronización completa
        # El usuario ya está guardado en Rails, solo falló la actualización de metadata
        Rails.logger.warn "Failed to update Supabase metadata for user #{@user.supabase_uid}: #{metadata_result.error}"
      end
    end

    def failure(message)
      @error = message
      self
    end
  end
end
