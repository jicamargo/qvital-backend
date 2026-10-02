require "test_helper"

class BodyRegionTest < ActiveSupport::TestCase
  test "focus_areas defaults to an empty array and only accepts known values" do
    region = BodyRegion.new(name: "Zona #{SecureRandom.hex(3)}", body_system: :peso_y_figura)
    assert_equal [], region.focus_areas
    assert region.valid?

    region.focus_areas = [ "control_peso" ]
    assert region.valid?

    region.focus_areas = [ "control_peso", "otro" ]
    refute region.valid?
    assert region.errors[:focus_areas].any?
  end

  test "with_focus_area returns only regions tagged with that focus" do
    tagged = BodyRegion.create!(name: "Tagged #{SecureRandom.hex(3)}", body_system: :peso_y_figura, focus_areas: [ "control_peso" ])
    untagged = BodyRegion.create!(name: "Untagged #{SecureRandom.hex(3)}", body_system: :digestivo)

    results = BodyRegion.with_focus_area("control_peso")
    assert_includes results, tagged
    refute_includes results, untagged
  end

  test "illustration_ref accepts only body map areas or nil" do
    region = BodyRegion.new(name: "Zona #{SecureRandom.hex(3)}", body_system: :digestivo)
    assert region.valid?

    region.illustration_ref = "abdomen"
    assert region.valid?

    region.illustration_ref = ""
    assert region.valid?
    assert_nil region.illustration_ref

    region.illustration_ref = "panza"
    refute region.valid?
    assert region.errors[:illustration_ref].any?
  end
end
