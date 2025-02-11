# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Tests for miscellaneous GEOS stuff
#
# -----------------------------------------------------------------------------

require "ostruct"
require_relative "../test_helper"
require_relative "../common/validity_tests"
require_relative "skip_capi"

class GeosMiscTest < Minitest::Test # :nodoc:
  def setup
    skip "Needs GEOS CAPI." unless RGeo::Geos.capi_supported?
    @factory = RGeo::Geos.factory(srid: 4326)
  end

  def test_marshal_dump_with_geos
    @factory = RGeo::Geos.factory(srid: 4326)

    dump = @factory.marshal_dump
    assert_equal({}, dump["wktg"])
    assert_equal({}, dump["wkbg"])
    assert_equal({}, dump["wktp"])
    assert_equal({}, dump["wkbp"])
  end

  def test_encode_with_geos
    @factory = RGeo::Geos.factory(srid: 4326)
    coder = Psych::Coder.new("test")

    @factory.encode_with(coder)
    assert_equal({}, coder["wkt_generator"])
    assert_equal({}, coder["wkb_generator"])
    assert_equal({}, coder["wkt_parser"])
    assert_equal({}, coder["wkb_parser"])
  end

  def test_uninitialized
    geom = RGeo::Geos::CAPIGeometryImpl.new
    assert_equal(false, geom.initialized?)
    assert_nil(geom.geometry_type)
  end

  def test_empty_geometries_equal
    geom1 = @factory.collection([])
    geom2 = @factory.line_string([])
    assert(!geom1.eql?(geom2))
    assert(geom1.equals?(geom2))
  end

  def test_invalid_geometry_equal_itself
    geom = @factory.parse_wkt("MULTIPOLYGON (((0 0, 1 1, 1 0, 0 0)), ((0 0, 2 2, 2 0, 0 0)))")
    assert(geom.eql?(geom))
    assert(geom.equals?(geom))
  end

  def test_prepare
    p1 = @factory.point(1, 2)
    p2 = @factory.point(3, 4)
    p3 = @factory.point(5, 2)
    polygon = @factory.polygon(@factory.linear_ring([p1, p2, p3, p1]))
    assert_equal(false, polygon.prepared?)
    polygon.prepare!
    assert_equal(true, polygon.prepared?)
  end

  def test_auto_prepare
    p1 = @factory.point(1, 2)
    p2 = @factory.point(3, 4)
    p3 = @factory.point(5, 2)
    polygon = @factory.polygon(@factory.linear_ring([p1, p2, p3, p1]))
    assert_equal(false, polygon.prepared?)
    polygon.intersects?(p1)
    assert_equal(false, polygon.prepared?)
    polygon.intersects?(p2)
    assert_equal(true, polygon.prepared?)

    factory_no_auto_prepare = RGeo::Geos.factory(srid: 4326, auto_prepare: :disabled)
    polygon2 = factory_no_auto_prepare.polygon(
      factory_no_auto_prepare.linear_ring([p1, p2, p3, p1])
    )
    assert_equal(false, polygon2.prepared?)
    polygon2.intersects?(p1)
    assert_equal(false, polygon2.prepared?)
    polygon2.intersects?(p2)
    assert_equal(false, polygon2.prepared?)
  end

  def test_gh_21
    # Test for GH-21 (seg fault in rgeo_convert_to_geos_geometry)
    # This seemed to fail under Ruby 1.8.7 only.
    f = RGeo::Geographic.simple_mercator_factory
    loc = f.line_string([f.point(-123, 37), f.point(-122, 38)])
    f2 = f.projection_factory
    loc2 = f2.line_string([f2.point(-123, 37), f2.point(-122, 38)])
    loc2.intersection(loc)
  end

  def test_geos_version
    assert_match(/^\d+\.\d+(\.\d+)?$/, RGeo::Geos.version)
  end

  def test_geos_wkb_parser_inputs
    c_factory = RGeo::Geos::CAPIFactory.new
    binary_wkb = "\x00\x00\x00\x00\a\x00\x00\x00\a\x00\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00" \
                 "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00@V\x80" \
                 "\x00\x00\x00\x00\x00@V\x80\x00\x00\x00\x00\x00@V\x80\x00\x00\x00\x00\x00@V\x80\x00\x00\x00\x00" \
                 "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" \
                 "\x00\x00\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x00\x05@^\x00\x00\x00\x00\x00\x00\x00\x00\x00" \
                 "\x00\x00\x00\x00\x00@^\x00\x00\x00\x00\x00\x00@V\x80\x00\x00\x00\x00\x00@j@\x00\x00\x00\x00" \
                 "\x00@V\x80\x00\x00\x00\x00\x00@j@\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00@^\x00\x00" \
                 "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x02@D\x00\x00" \
                 "\x00\x00\x00\x00@I\x00\x00\x00\x00\x00\x00@D\x00\x00\x00\x00\x00\x00@a\x80\x00\x00\x00\x00\x00" \
                 "\x00\x00\x00\x00\x02\x00\x00\x00\x02@d\x00\x00\x00\x00\x00\x00@I\x00\x00\x00\x00\x00\x00@d\x00" \
                 "\x00\x00\x00\x00\x00@a\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01@N\x00\x00\x00\x00\x00\x00@I" \
                 "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01@N\x00\x00\x00\x00\x00\x00@a\x80\x00\x00\x00\x00\x00" \
                 "\x00\x00\x00\x00\x01@D\x00\x00\x00\x00\x00\x00@a\x80\x00\x00\x00\x00\x00"

    wkt = @factory.parse_wkb(binary_wkb).as_text
    assert_equal(wkt, c_factory.parse_wkb(binary_wkb).as_text)

    hexidecimal_wkb = "000000000700000007000000000300000001000000050000000000000000000000000000000000000000000000" \
                      "004056800000000000405680000000000040568000000000004056800000000000000000000000000000000000" \
                      "00000000000000000000000000000000030000000100000005405e0000000000000000000000000000405e0000" \
                      "000000004056800000000000406a4000000000004056800000000000406a400000000000000000000000000040" \
                      "5e0000000000000000000000000000000000000200000002404400000000000040490000000000004044000000" \
                      "000000406180000000000000000000020000000240640000000000004049000000000000406400000000000040" \
                      "618000000000000000000001404e00000000000040490000000000000000000001404e00000000000040618000" \
                      "00000000000000000140440000000000004061800000000000"

    assert_equal(wkt, c_factory.parse_wkb(hexidecimal_wkb).as_text)
  end

  def test_unary_union_simple_points
    p1 = @factory.point(1, 1)
    p2 = @factory.point(2, 2)
    mp = @factory.multi_point([p1, p2])
    collection = @factory.collection([p1, p2])
    geom = collection.unary_union
    if RGeo::Geos::CAPIFactory._supports_unary_union?
      assert(geom.eql?(mp))
    else
      assert_equal(nil, geom)
    end
  end

  def test_unary_union_mixed_collection
    geometrycollection = "GEOMETRYCOLLECTION (POLYGON ((0 0, 0 90, 90 90, 90 0, 0 0)), " \
                         "POLYGON ((120 0, 120 90, 210 90, 210 0, 120 0)), " \
                         "LINESTRING (40 50, 40 140), " \
                         "LINESTRING (160 50, 160 140), " \
                         "POINT (60 50), " \
                         "POINT (60 140), " \
                         "POINT (40 140))"
    expected_geometrycollection = "GEOMETRYCOLLECTION (POINT (60 140), " \
                                  "LINESTRING (40 90, 40 140), " \
                                  "LINESTRING (160 90, 160 140), " \
                                  "POLYGON ((0 0, 0 90, 40 90, 90 90, 90 0, 0 0)), " \
                                  "POLYGON ((120 0, 120 90, 160 90, 210 90, 210 0, 120 0)))"
    collection = @factory.parse_wkt(geometrycollection)
    expected = @factory.parse_wkt(expected_geometrycollection)
    geom = collection.unary_union
    if RGeo::Geos::CAPIFactory._supports_unary_union?
      # Note that here `.eql?` is not guaranteed on all GEOS implementation.
      assert(geom == expected)
    else
      assert_equal(nil, geom)
    end
  end

  def test_casting_dumb_objects
    assert_raises(RGeo::Error::RGeoError) do
      # We use an OpenStruct here because we want an object that respond `nil` to unknown methods.
      RGeo::Geos.factory.point(1, 1).contains?(OpenStruct.new(factory: RGeo::Geos.factory)) # rubocop:disable Style/OpenStructUse
    end
  end

  def test_polygon_creation_invalid_cast
    assert_raises(RGeo::Error::RGeoError) do
      fac = RGeo::Geos.factory
      points = [fac.point(0, 0), fac.point(0, 1), fac.point(1, 1), fac.point(1, 0)]
      shell = fac.linear_ring(points)

      fake_geom = Struct.new(:factory)
      hole = fake_geom.new(factory: fac)

      # test that polygon creation will properly free data on a cast error
      fac.polygon(shell, [shell, hole])
    end
  end
end

puts "WARNING: GEOS CAPI support not available. Related tests skipped." unless RGeo::Geos.capi_supported?
