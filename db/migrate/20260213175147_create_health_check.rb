class CreateHealthCheck < ActiveRecord::Migration[8.0]
  def change
    create_table :health_checks do |t|
      t.string :name

      t.timestamps
    end
  end
end
