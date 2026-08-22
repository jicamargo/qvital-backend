class BodyRegionBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :body_system, :display_order, :illustration_ref, :parent_id

  view :admin do
    fields :active, :created_at, :updated_at
  end
end
