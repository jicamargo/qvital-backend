require "test_helper"

module Api
  module V1
    class TrackingControllerTest < ActionDispatch::IntegrationTest
      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "tracking-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
      end

      test "index requires authentication" do
        get api_v1_tracking_index_path, as: :json

        assert_response :unauthorized
      end

      test "index returns the user's entries most recent first" do
        older = TrackingEntry.create!(user: @user, weight_kg: 80, recorded_on: 2.days.ago.to_date, created_at: 2.days.ago)
        newer = TrackingEntry.create!(user: @user, weight_kg: 79, recorded_on: 1.day.ago.to_date, created_at: 1.day.ago)

        stub_authenticated_as(@user) do
          get api_v1_tracking_index_path, headers: auth_headers, as: :json
        end

        assert_response :success
        ids = JSON.parse(response.body)["entries"].map { |e| e["id"] }
        assert_equal [ newer.id, older.id ], ids
      end

      test "index does not return another user's entries" do
        other_user = User.create!(email: "tracking-other-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        TrackingEntry.create!(user: other_user, weight_kg: 70)

        stub_authenticated_as(@user) do
          get api_v1_tracking_index_path, headers: auth_headers, as: :json
        end

        assert_response :success
        assert_empty JSON.parse(response.body)["entries"]
      end

      test "create persists a valid entry for the current user" do
        stub_authenticated_as(@user) do
          assert_difference "TrackingEntry.count", 1 do
            post api_v1_tracking_index_path,
                 params: { weight_kg: "72.5", waist_cm: "85.0", mood: "bueno", energy_level: "media", habits_completed: 2 },
                 headers: auth_headers, as: :json
          end
        end

        assert_response :created
        entry = JSON.parse(response.body)["entry"]
        assert_equal "72.5", entry["weight_kg"]
        assert_equal "85.0", entry["waist_cm"]
        assert_equal @user.id, TrackingEntry.last.user_id
      end

      test "create upserts today's entry instead of creating a duplicate" do
        stub_authenticated_as(@user) do
          assert_difference "TrackingEntry.count", 1 do
            post api_v1_tracking_index_path, params: { weight_kg: "72.5" }, headers: auth_headers, as: :json
          end
        end
        assert_response :created

        stub_authenticated_as(@user) do
          assert_no_difference "TrackingEntry.count" do
            post api_v1_tracking_index_path, params: { weight_kg: "71.0", waist_cm: "84.0" }, headers: auth_headers, as: :json
          end
        end
        assert_response :success

        entry = JSON.parse(response.body)["entry"]
        assert_equal "71.0", entry["weight_kg"]
        assert_equal "84.0", entry["waist_cm"]
        assert_equal Date.current.to_s, TrackingEntry.last.recorded_on.to_s
      end

      test "create rejects a missing weight" do
        stub_authenticated_as(@user) do
          assert_no_difference "TrackingEntry.count" do
            post api_v1_tracking_index_path, params: { mood: "bueno" }, headers: auth_headers, as: :json
          end
        end

        assert_response :unprocessable_entity
        assert JSON.parse(response.body)["details"].key?("weight_kg")
      end

      test "prefill reports first entry and no evaluation lead when none matches" do
        stub_authenticated_as(@user) do
          get prefill_api_v1_tracking_index_path, headers: auth_headers, as: :json
        end

        assert_response :success
        body = JSON.parse(response.body)
        assert body["is_first_entry"]
        assert_nil body["evaluation_lead"]
        assert_nil body["today_entry"]
      end

      test "prefill returns today's entry when the user already registered today" do
        entry = TrackingEntry.create!(user: @user, weight_kg: 72.5, waist_cm: 85)

        stub_authenticated_as(@user) do
          get prefill_api_v1_tracking_index_path, headers: auth_headers, as: :json
        end

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal entry.id, body["today_entry"]["id"]
        assert_equal "72.5", body["today_entry"]["weight_kg"]
      end

      test "prefill's today_entry is nil when the user's only entry is from a previous day" do
        TrackingEntry.create!(user: @user, weight_kg: 70, recorded_on: 1.day.ago.to_date, created_at: 1.day.ago)

        stub_authenticated_as(@user) do
          get prefill_api_v1_tracking_index_path, headers: auth_headers, as: :json
        end

        assert_response :success
        assert_nil JSON.parse(response.body)["today_entry"]
      end

      test "prefill returns the most recent evaluation lead matching the user's email" do
        EvaluationLead.create!(email: @user.email, weight_kg: 90, waist_cm: 95, created_at: 2.days.ago)
        latest = EvaluationLead.create!(email: @user.email, weight_kg: 88, waist_cm: 92, created_at: 1.day.ago)

        stub_authenticated_as(@user) do
          get prefill_api_v1_tracking_index_path, headers: auth_headers, as: :json
        end

        assert_response :success
        body = JSON.parse(response.body)
        assert body["is_first_entry"]
        assert_equal latest.id, body["evaluation_lead"]["id"]
        assert_equal "88.0", body["evaluation_lead"]["weight_kg"]
      end

      test "prefill is not first entry once the user already has one" do
        TrackingEntry.create!(user: @user, weight_kg: 70)
        EvaluationLead.create!(email: @user.email, weight_kg: 90, waist_cm: 95)

        stub_authenticated_as(@user) do
          get prefill_api_v1_tracking_index_path, headers: auth_headers, as: :json
        end

        assert_response :success
        body = JSON.parse(response.body)
        refute body["is_first_entry"]
        assert_nil body["evaluation_lead"]
      end
    end
  end
end
