require "test_helper"

module Api
  module V1
    class EvaluationLeadsControllerTest < ActionDispatch::IntegrationTest
      test "create with a valid email succeeds without authentication" do
        assert_difference "EvaluationLead.count", 1 do
          post api_v1_evaluation_leads_path, params: { email: "lead-#{SecureRandom.hex(4)}@example.com", age: 30 }, as: :json
        end

        assert_response :created
        body = JSON.parse(response.body)
        assert body["email"].present?
      end

      test "create without an email fails validation" do
        assert_no_difference "EvaluationLead.count" do
          post api_v1_evaluation_leads_path, params: { age: 30 }, as: :json
        end

        assert_response :unprocessable_entity
        body = JSON.parse(response.body)
        assert body["details"].key?("email")
      end
    end
  end
end
