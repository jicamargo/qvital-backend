# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Permitir requests desde frontend/local en desarrollo.
    if Rails.env.development?
      dev_origins = [
        "http://localhost:3000",
        "http://127.0.0.1:3000"
      ]
      dev_origins << ENV["FRONTEND_URL"] if ENV["FRONTEND_URL"].present?
      origins(*dev_origins.uniq)
    else
      origins ENV.fetch("FRONTEND_URL", "*")
    end

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end
