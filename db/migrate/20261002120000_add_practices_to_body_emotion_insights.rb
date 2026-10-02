# Prácticas cortas (0-3) que la usuaria puede elegir en una ficha de la
# Brújula Corporal. Cada elemento: { "title" => String, "description" => String }.
class AddPracticesToBodyEmotionInsights < ActiveRecord::Migration[8.0]
  def change
    add_column :body_emotion_insights, :practices, :jsonb, default: [], null: false
  end
end
