class VirtualCoachProfileBlueprint < Blueprinter::Base
  identifier :id

  fields :display_name, :gender, :specialty_description, :tone_profile, :avatar_url

  view :admin do
    fields :active, :created_at, :updated_at
  end
end
