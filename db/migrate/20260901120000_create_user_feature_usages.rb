class CreateUserFeatureUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :user_feature_usages do |t|
      t.references :user, null: false, foreign_key: true
      t.string   :feature_key, null: false
      t.datetime :last_used_at, null: false
      t.integer  :use_count, default: 0, null: false

      t.timestamps
    end
    add_index :user_feature_usages, [:user_id, :feature_key], unique: true
  end
end
