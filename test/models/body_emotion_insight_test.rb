require "test_helper"

class BodyEmotionInsightTest < ActiveSupport::TestCase
  def build_insight(practices)
    region = BodyRegion.create!(name: "Zona #{SecureRandom.hex(3)}", body_system: :digestivo)
    BodyEmotionInsight.new(body_region: region, symptom_pattern: "x", emotional_theme: "x",
                           narrative_explanation: "x", integration_guidance: "x", practices: practices)
  end

  test "practices defaults to empty and accepts up to 3 valid items" do
    assert_equal [], BodyEmotionInsight.new.practices
    assert build_insight([]).valid?
    assert build_insight(Array.new(3) { { "title" => "Pausa", "description" => "Respira 3 veces." } }).valid?
  end

  test "rejects more than 3 practices" do
    refute build_insight(Array.new(4) { { "title" => "a", "description" => "b" } }).valid?
  end

  test "rejects title over 50 chars, description over 140, blanks, and extra keys" do
    refute build_insight([ { "title" => "a" * 51, "description" => "b" } ]).valid?
    refute build_insight([ { "title" => "a", "description" => "b" * 141 } ]).valid?
    refute build_insight([ { "title" => "", "description" => "b" } ]).valid?
    refute build_insight([ { "title" => "a", "description" => "b", "extra" => 1 } ]).valid?
  end
end
