class CoachConsultationBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :started_at, :ended_at, :session_summary

  association :virtual_coach_profile, blueprint: VirtualCoachProfileBlueprint

  field :body_regions_summary do |consultation|
    consultation.body_regions_summary
  end

  view :with_entries do
    association :coach_consultation_entries, blueprint: CoachConsultationEntryBlueprint
  end
end
