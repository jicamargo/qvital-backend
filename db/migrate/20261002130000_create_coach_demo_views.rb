# Registro de cada vez que una usuaria (premium o no) ve la demo de la
# Brújula Corporal para una zona. Sirve para medir el uso de la vitrina.
class CreateCoachDemoViews < ActiveRecord::Migration[8.0]
  def change
    create_table :coach_demo_views do |t|
      t.references :user, null: false, foreign_key: true
      t.references :body_region, null: false, foreign_key: true
      t.datetime :created_at, null: false
    end

    add_index :coach_demo_views, %i[user_id created_at]
  end
end
