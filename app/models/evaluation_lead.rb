class EvaluationLead < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { only_integer: true, greater_than: 0, less_than: 130 }, allow_nil: true
  validates :weight_kg, numericality: { greater_than: 0, less_than: 500 }, allow_nil: true
  validates :height_cm, numericality: { greater_than: 0, less_than: 300 }, allow_nil: true
  validates :waist_cm, numericality: { greater_than: 0, less_than: 300 }, allow_nil: true
end
