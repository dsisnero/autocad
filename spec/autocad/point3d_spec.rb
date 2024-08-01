require_relative "../test_helper"

describe Autocad::Point3d do
  describe "#initialize" do
    it "defaults to 0,0,0" do
      pt = Autocad::Point3d.new
      _(pt.x).must_equal(0.0)
      _(pt.y).must_equal(0.0)
      _(pt.z).must_equal(0.0)
    end

    it "lets you specify with points" do
      pt = Autocad::Point3d.new(1, 2, 3)
      _(pt.x).must_equal(1.0)
      _(pt.y).must_equal(2.0)
      _(pt.z).must_equal(3.0)
    end

    it "allows you to supply only a few points" do
      pt = Autocad::Point3d.new(1, 2)
      _(pt.x).must_equal(1.0)
      _(pt.y).must_equal(2.0)
      _(pt.z).must_equal(0.0)
    end

    it "allows you to supply an array" do
      pt = Autocad::Point3d.new([1, 2, 3])
      _(pt).must_be_instance_of(Autocad::Point3d)
      _(pt.x).must_equal(1.0)
      _(pt.y).must_equal(2.0)
      _(pt.z).must_equal(3.0)
    end
  end
  it "allows you to add lines and points" do
    p1 = Point3d(0, 0)
    p2 = Point3d(50, 25)
    p3 = p1 + p2
    _(p3).must_be_instance_of(Autocad::Point3d)
    _(p3.to_ary).must_equal([50.0, 25.0, 0.0])
  end
end
