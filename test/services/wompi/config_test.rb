require "test_helper"

module Wompi
  class ConfigTest < ActiveSupport::TestCase
    REQUIRED = %w[
      WOMPI_ENV WOMPI_PUBLIC_KEY WOMPI_PRIVATE_KEY WOMPI_INTEGRITY_SECRET
      WOMPI_EVENTS_SECRET WOMPI_API_BASE_URL WOMPI_REDIRECT_URL
    ].freeze

    def with_env(values)
      saved = REQUIRED.index_with { |key| ENV[key] }
      REQUIRED.each { |key| ENV.delete(key) }
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      saved.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end

    def complete_env(overrides = {})
      REQUIRED.index_with { |key| "#{key.downcase}-value" }
              .merge("WOMPI_ENV" => "production", "WOMPI_API_BASE_URL" => "https://production.wompi.co/v1")
              .merge(overrides)
    end

    test "lists every missing variable" do
      with_env({}) do
        assert_equal REQUIRED.sort, Config.production_problems.map { |p| p[/WOMPI_\w+/] }.sort
      end
    end

    test "reports nothing when everything is set" do
      with_env(complete_env) do
        assert_empty Config.production_problems
      end
    end

    test "flags production keys pointed at the sandbox API" do
      with_env(complete_env("WOMPI_API_BASE_URL" => "https://sandbox.wompi.co/v1")) do
        assert_match(/sandbox/i, Config.production_problems.join)
      end
    end
  end
end
