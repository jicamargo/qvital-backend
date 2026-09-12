class MakeUserHabitsNameUniqueOnlyAmongActive < ActiveRecord::Migration[8.0]
  def change
    # El índice original bloqueaba reusar el nombre de un hábito ya archivado
    # (mismo bug que la validación del modelo, a nivel de DB) — un usuario no
    # podía volver a crear "Tomar agua" después de archivarlo.
    remove_index :user_habits, name: "index_user_habits_on_user_id_and_name"
    add_index :user_habits, [ :user_id, :name ], unique: true, where: "active",
              name: "index_user_habits_on_user_id_and_name_when_active"
  end
end
