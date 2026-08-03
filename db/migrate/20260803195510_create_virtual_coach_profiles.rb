class CreateVirtualCoachProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :virtual_coach_profiles do |t|
      t.string :display_name, null: false
      t.integer :gender, null: false, default: 0
      t.string :specialty_description, null: false, default: "Conexión Cuerpo-Emoción"
      t.jsonb :tone_profile, null: false, default: {}
      t.string :avatar_url
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :virtual_coach_profiles, :active
  end
end
