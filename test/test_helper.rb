ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Uncomment to run tests in parallel again once every worker has its own
    # populated qvital_test-N database (today's qvital_test is seeded via
    # pg_restore, not db:schema:load, see docs/database.md — a second worker
    # DB would come up empty and every test would fail).
    # parallelize(workers: :number_of_processors)

    # `Api::V1::BaseController` (and any controller that includes Authenticatable)
    # calls Auth::SyncUser.call(token:), which fetches Supabase's real JWKS over
    # the network to verify the JWT (see app/interactors/auth/sync_user.rb). Tests
    # stub that one interactor call instead of minting real signed tokens, so
    # controller specs run offline and don't depend on Supabase being reachable.
    #
    # Minitest 6 dropped Object#stub/Minitest::Mock, so this replaces the class
    # method by hand for the duration of the block instead of pulling in a
    # mocking gem for one call site.
    def stub_sync_user(result, &block)
      original_method = Auth::SyncUser.method(:call)
      Auth::SyncUser.define_singleton_method(:call) { |*| result }
      block.call
    ensure
      Auth::SyncUser.define_singleton_method(:call, original_method)
    end

    def stub_authenticated_as(user, &block)
      fake_result = Struct.new(:user) do
        def success?
          true
        end
      end.new(user)

      stub_sync_user(fake_result, &block)
    end

    def auth_headers
      { "Authorization" => "Bearer test-token" }
    end
  end
end
