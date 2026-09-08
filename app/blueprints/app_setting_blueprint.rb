class AppSettingBlueprint < Blueprinter::Base
  identifier :id

  fields :premium_purchase_threshold, :updated_at
end
