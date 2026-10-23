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

    REQUIRED_VARIABLES = %w[
      WOMPI_ENV WOMPI_PUBLIC_KEY WOMPI_PRIVATE_KEY WOMPI_INTEGRITY_SECRET
      WOMPI_EVENTS_SECRET WOMPI_API_BASE_URL WOMPI_REDIRECT_URL
    ].freeze

    # Problemas que impiden cobrar bien en producción. Los defaults de arriba
    # apuntan al sandbox: en producción no se puede depender de ellos, porque
    # el checkout "funcionaría" sin cobrar dinero real.
    def production_problems
      problems = REQUIRED_VARIABLES.select { |key| ENV[key].blank? }.map { |key| "Falta #{key}" }

      if ENV["WOMPI_ENV"] == "production" && ENV["WOMPI_API_BASE_URL"].to_s.include?("sandbox")
        problems << "WOMPI_ENV=production pero WOMPI_API_BASE_URL apunta al sandbox"
      end

      problems
    end
  end
end
