class UserHabit < ApplicationRecord
  MAX_ACTIVE_PER_USER = 5

  belongs_to :user
  has_many :habit_completions, dependent: :destroy

  validates :name, presence: true, length: { maximum: 60 }
  # `conditions:` limita la comparación a hábitos activos — sin esto, `if: :active?`
  # solo decide si esta validación corre sobre el registro nuevo, pero seguiría
  # comparando contra hábitos archivados con el mismo nombre (bug real: bloqueaba
  # reusar el nombre de un hábito ya archivado, que es justo el caso que debía permitir).
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false, conditions: -> { where(active: true) } },
                    if: :active?

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :created_at) }
end
