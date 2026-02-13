class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :encrypted_password
      t.string :role, null: false, default: 'cliente'
      t.references :level, null: true, foreign_key: true
      t.string :supabase_uid
      t.string :hlf_id
      t.string :nombre

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :supabase_uid, unique: true
    add_index :users, :hlf_id, unique: true
    add_index :users, :role
  end
end
