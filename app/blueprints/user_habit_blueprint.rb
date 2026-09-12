class UserHabitBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :position

  field :completed_dates do |habit, options|
    (options[:completions_by_habit_id]&.[](habit.id) || []).map(&:to_s)
  end
end
