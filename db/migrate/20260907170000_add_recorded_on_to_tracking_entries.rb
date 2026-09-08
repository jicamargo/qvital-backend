class AddRecordedOnToTrackingEntries < ActiveRecord::Migration[8.0]
  def up
    add_column :tracking_entries, :recorded_on, :date
    execute "UPDATE tracking_entries SET recorded_on = created_at::date WHERE recorded_on IS NULL"

    # Antes de esta migración no existía la restricción "un registro por día":
    # si por pruebas manuales quedó más de uno para el mismo (user_id, recorded_on),
    # nos quedamos con el más reciente (mismo criterio que usará Tracking::Upsert).
    execute <<~SQL
      DELETE FROM tracking_entries a
      USING tracking_entries b
      WHERE a.user_id = b.user_id
        AND a.recorded_on = b.recorded_on
        AND a.id < b.id
    SQL

    change_column_null :tracking_entries, :recorded_on, false

    # Un solo registro por usuario por día — refuerza a nivel de DB lo que
    # Tracking::Upsert ya garantiza a nivel de aplicación.
    add_index :tracking_entries, [ :user_id, :recorded_on ], unique: true
  end

  def down
    remove_index :tracking_entries, [ :user_id, :recorded_on ]
    remove_column :tracking_entries, :recorded_on
  end
end
