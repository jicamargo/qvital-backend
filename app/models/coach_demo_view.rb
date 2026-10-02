# Vista de la demo de la Brújula Corporal (solo created_at, sin updated_at).
class CoachDemoView < ApplicationRecord
  belongs_to :user
  belongs_to :body_region
end
