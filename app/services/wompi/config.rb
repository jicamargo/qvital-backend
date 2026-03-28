module Wompi
  module Config
    module_function

    def env
      ENV.fetch("WOMPI_ENV", "sandbox")
    end

    def checkout_url
      ENV.fetch("WOMPI_CHECKOUT_URL", "https://checkout.wompi.co/p/")
    end

    def api_base_url
      ENV.fetch("WOMPI_API_BASE_URL", "https://sandbox.wompi.co/v1")
    end

    def public_key
      ENV["WOMPI_PUBLIC_KEY"]
    end

    def private_key
      ENV["WOMPI_PRIVATE_KEY"]
    end

    def integrity_secret
      ENV["WOMPI_INTEGRITY_SECRET"]
    end

    def events_secret
      ENV["WOMPI_EVENTS_SECRET"]
    end

    def redirect_url
      ENV["WOMPI_REDIRECT_URL"]
    end

    def expected_webhook_environment
      env.to_s == "production" ? "prod" : "test"
    end
  end
end
