require "test_helper"

# Valida el contenido de db/seed_data/body_emotion/*.yml (lo lee db/seeds.rb):
# que cada zona tenga una ficha completa y válida para el modelo, para que un
# error de redacción en un YAML falle acá y no a mitad de un db:seed.
class BodyEmotionSeedDataTest < ActiveSupport::TestCase
  SEED_FILES = Dir[Rails.root.join("db/seed_data/body_emotion/*.yml")].sort

  def seed_data
    @seed_data ||= SEED_FILES.map { |file| [ File.basename(file), YAML.load_file(file, aliases: true).deep_symbolize_keys ] }
  end

  def all_regions
    seed_data.flat_map { |_, data| data[:regions] }
  end

  test "there is one seed file per body_system" do
    assert_equal BodyRegion.body_systems.keys.sort, seed_data.map { |_, data| data[:body_system] }.sort
  end

  test "region names are unique across all files" do
    duplicates = all_regions.map { |r| r[:name] }.tally.select { |_, count| count > 1 }.keys
    assert_empty duplicates
  end

  test "every region has a complete insight" do
    seed_data.each do |file, data|
      data[:regions].each do |region|
        insight = region[:insight]
        context = "#{file} → #{region[:name]}"

        assert region[:display_order].is_a?(Integer), "#{context}: display_order debe ser entero"
        %i[symptom_pattern emotional_theme narrative_explanation integration_guidance content_curation_notes].each do |field|
          assert insight[field].present?, "#{context}: falta #{field}"
        end
        assert_equal 3, insight[:reflective_questions]&.size, "#{context}: se esperan 3 preguntas reflexivas"
        assert insight[:tags].present? && insight[:tags].all? { |t| t.match?(/\A[a-z0-9_]+\z/) },
               "#{context}: tags deben ser snake_case sin tildes"
        assert_includes BodyEmotionInsight.severity_flags.keys, insight[:severity_flag], "#{context}: severity_flag inválido"
        assert_nil insight[:status], "#{context}: el status lo decide seeds.rb, no el YAML"
        assert_match(/profesional/i, insight[:integration_guidance], "#{context}: la guía debe recomendar consultar a un profesional")
      end
    end
  end

  test "chest and breathing insights suggest professional support" do
    %w[Pecho\ /\ corazón Pulmones\ /\ respiración].each do |name|
      region = all_regions.find { |r| r[:name] == name }
      assert region, "falta la zona #{name}"
      assert_equal "sugerir_acompanamiento_profesional", region[:insight][:severity_flag]
    end
  end

  test "weight-focused zones close with the eating-disorder referral line" do
    peso_y_figura = seed_data.find { |_, data| data[:body_system] == "peso_y_figura" }&.last
    assert peso_y_figura, "falta peso_y_figura.yml"

    peso_y_figura[:regions].each do |region|
      assert_equal [ "control_peso" ], region[:focus_areas], "#{region[:name]}: debe tener focus_areas control_peso"
      guidance = region[:insight][:integration_guidance]
      assert_match(/atracones/, guidance, "#{region[:name]}: falta la línea de derivación por TCA (plan §3.3)")
      assert_match(/profesional de salud mental/, guidance, "#{region[:name]}: falta la línea de derivación por TCA (plan §3.3)")
    end
  end

  test "the Peso y emociones filter also includes the related existing zones" do
    weight_zones = all_regions.select { |r| Array(r[:focus_areas]).include?("control_peso") }.map { |r| r[:name] }
    [ "Sueño / insomnio", "Cansancio persistente", "Estómago / sistema digestivo", "Intestinos / colon",
      "Hígado / vesícula" ].each do |name|
      assert_includes weight_zones, name
    end
  end

  test "every region and insight is valid for the models" do
    all_regions.each do |attrs|
      region = BodyRegion.new(name: "#{attrs[:name]} (test)", body_system: seed_data.find { |_, d| d[:regions].include?(attrs) }.last[:body_system],
                              display_order: attrs[:display_order], focus_areas: attrs[:focus_areas] || [])
      assert region.valid?, "#{attrs[:name]}: #{region.errors.full_messages.to_sentence}"

      insight = BodyEmotionInsight.new(attrs[:insight].merge(body_region: region))
      assert insight.valid?, "#{attrs[:name]}: #{insight.errors.full_messages.to_sentence}"
    end
  end

  test "every region has a valid body map area" do
    all_regions.each do |region|
      assert_includes BodyRegion::BODY_MAP_AREAS, region[:illustration_ref], "#{region[:name]}: illustration_ref inválido"
    end
  end

  test "body map mapping matches the spec" do
    areas = all_regions.to_h { |r| [ r[:name], r[:illustration_ref] ] }
    assert_equal "abdomen", areas["Estómago / sistema digestivo"]
    assert_equal "espalda_baja", areas["Zona lumbar"]
    assert_equal "todo_cuerpo", areas["Hambre emocional / antojos"]
  end
end
