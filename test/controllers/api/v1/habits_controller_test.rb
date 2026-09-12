require "test_helper"

module Api
  module V1
    class HabitsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "habits-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
      end

      test "index requires authentication" do
        get api_v1_habits_path, as: :json

        assert_response :unauthorized
      end

      test "index returns only the current user's active habits, ordered, with this week's completions" do
        habit = UserHabit.create!(user: @user, name: "Tomar agua", position: 1)
        archived = UserHabit.create!(user: @user, name: "Archivado", position: 2, active: false)
        other_user = User.create!(email: "habits-other-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        UserHabit.create!(user: other_user, name: "No debería verse", position: 1)

        HabitCompletion.create!(user_habit: habit, completed_on: Date.current)

        stub_authenticated_as(@user) do
          get api_v1_habits_path, headers: auth_headers, as: :json
        end

        assert_response :success
        body = JSON.parse(response.body)
        names = body["habits"].map { |h| h["name"] }
        assert_equal [ "Tomar agua" ], names
        refute_includes names, archived.name
        assert_equal [ Date.current.to_s ], body["habits"].first["completed_dates"]
      end

      test "create persists a habit for the current user" do
        stub_authenticated_as(@user) do
          assert_difference "UserHabit.count", 1 do
            post api_v1_habits_path, params: { name: "Caminar 10 min" }, headers: auth_headers, as: :json
          end
        end

        assert_response :created
        habit = JSON.parse(response.body)["habit"]
        assert_equal "Caminar 10 min", habit["name"]
        assert_empty habit["completed_dates"]
        assert_equal @user.id, UserHabit.last.user_id
      end

      test "create rejects a duplicate active habit name for the same user" do
        UserHabit.create!(user: @user, name: "Tomar agua", position: 1)

        stub_authenticated_as(@user) do
          assert_no_difference "UserHabit.count" do
            post api_v1_habits_path, params: { name: "Tomar agua" }, headers: auth_headers, as: :json
          end
        end

        assert_response :unprocessable_entity
        assert JSON.parse(response.body)["details"].key?("name")
      end

      test "create allows reusing the name of a habit the user already archived" do
        archived = UserHabit.create!(user: @user, name: "Tomar agua", position: 1, active: false)

        stub_authenticated_as(@user) do
          assert_difference "UserHabit.count", 1 do
            post api_v1_habits_path, params: { name: "Tomar agua" }, headers: auth_headers, as: :json
          end
        end

        assert_response :created
        habit = JSON.parse(response.body)["habit"]
        assert_equal "Tomar agua", habit["name"]
        refute_equal archived.id, habit["id"]
      end

      test "create rejects a 6th active habit" do
        5.times { |i| UserHabit.create!(user: @user, name: "Habito #{i}", position: i) }

        stub_authenticated_as(@user) do
          assert_no_difference "UserHabit.count" do
            post api_v1_habits_path, params: { name: "Uno de más" }, headers: auth_headers, as: :json
          end
        end

        assert_response :unprocessable_entity
        assert_match(/máximo de 5/, JSON.parse(response.body)["error"])
      end

      test "destroy archives the habit instead of deleting it" do
        habit = UserHabit.create!(user: @user, name: "Tomar agua", position: 1)

        stub_authenticated_as(@user) do
          assert_no_difference "UserHabit.count" do
            delete api_v1_habit_path(habit), headers: auth_headers, as: :json
          end
        end

        assert_response :no_content
        refute habit.reload.active?
      end

      test "destroy does not allow archiving another user's habit" do
        other_user = User.create!(email: "habits-other-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        habit = UserHabit.create!(user: other_user, name: "Tomar agua", position: 1)

        stub_authenticated_as(@user) do
          delete api_v1_habit_path(habit), headers: auth_headers, as: :json
        end

        assert_response :not_found
        assert habit.reload.active?
      end

      test "toggle_completion marks today as done, then unmarks it" do
        habit = UserHabit.create!(user: @user, name: "Tomar agua", position: 1)

        stub_authenticated_as(@user) do
          assert_difference "HabitCompletion.count", 1 do
            post toggle_completion_api_v1_habit_path(habit), params: { date: Date.current.to_s }, headers: auth_headers, as: :json
          end
        end
        assert_response :success
        assert JSON.parse(response.body)["completed"]

        stub_authenticated_as(@user) do
          assert_difference "HabitCompletion.count", -1 do
            post toggle_completion_api_v1_habit_path(habit), params: { date: Date.current.to_s }, headers: auth_headers, as: :json
          end
        end
        assert_response :success
        refute JSON.parse(response.body)["completed"]
      end

      test "toggle_completion rejects a future date" do
        habit = UserHabit.create!(user: @user, name: "Tomar agua", position: 1)

        stub_authenticated_as(@user) do
          assert_no_difference "HabitCompletion.count" do
            post toggle_completion_api_v1_habit_path(habit), params: { date: 1.day.from_now.to_date.to_s }, headers: auth_headers, as: :json
          end
        end

        assert_response :unprocessable_entity
      end

      test "toggle_completion rejects a habit that does not belong to the current user" do
        other_user = User.create!(email: "habits-other-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        habit = UserHabit.create!(user: other_user, name: "Tomar agua", position: 1)

        stub_authenticated_as(@user) do
          post toggle_completion_api_v1_habit_path(habit), params: { date: Date.current.to_s }, headers: auth_headers, as: :json
        end

        assert_response :unprocessable_entity
      end
    end
  end
end
