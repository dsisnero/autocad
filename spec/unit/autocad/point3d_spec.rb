require_relative '../../spec_helper'

describe Autocad::Point3d do
  describe '#initialize' do
    it 'defaults to 0,0,0' do
      pt = Autocad::Point3d.new
      _(pt.x).must_equal(0.0)
      _(pt.y).must_equal(0.0)
      _(pt.z).must_equal(0.0)
    end

    it 'lets you specify with points' do
      pt = Autocad::Point3d.new(1, 2, 3)
      _(pt.x).must_equal(1.0)
      _(pt.y).must_equal(2.0)
      _(pt.z).must_equal(3.0)
    end

    it 'allows you to supply only a few points' do
      pt = Autocad::Point3d.new(1, 2)
      _(pt.x).must_equal(1.0)
      _(pt.y).must_equal(2.0)
      _(pt.z).must_equal(0.0)
    end

    it 'allows you to supply an array' do
      pt = Autocad::Point3d.new([1, 2, 3])
      _(pt).must_be_instance_of(Autocad::Point3d)
      _(pt.x).must_equal(1.0)
      _(pt.y).must_equal(2.0)
      _(pt.z).must_equal(3.0)
    end

    it 'allows you to supply another Point3d' do
      original = Autocad::Point3d.new(1, 2, 3)
      pt = Autocad::Point3d.new(original)
      _(pt).must_be_instance_of(Autocad::Point3d)
      _(pt.x).must_equal(1.0)
      _(pt.y).must_equal(2.0)
      _(pt.z).must_equal(3.0)
    end
  end
  it 'allows you to add lines and points' do
    p1 = Point3d(0, 0)
    p2 = Point3d(50, 25)
    p3 = p1 + p2
    _(p3).must_be_instance_of(Autocad::Point3d)
    _(p3.to_ary).must_equal([50.0, 25.0, 0.0])
  end

  describe '.pts_to_array' do
    it 'converts array of Point3d objects to flat array of x,y coordinates' do
      pts = [
        Autocad::Point3d.new(1, 2, 3),
        Autocad::Point3d.new(4, 5, 6)
      ]
      _(Autocad::Point3d.pts_to_array(pts)).must_equal([1.0, 2.0, 4.0, 5.0])
    end

    it 'converts array of coordinate arrays to flat array of x,y coordinates' do
      pts = [[1, 2, 3], [4, 5, 6]]
      _(Autocad::Point3d.pts_to_array(pts)).must_equal([1.0, 2.0, 4.0, 5.0])
    end

    it 'handles array of 2D coordinate arrays' do
      pts = [[1, 2], [3, 4]]
      _(Autocad::Point3d.pts_to_array(pts)).must_equal([1.0, 2.0, 3.0, 4.0])
    end

    it 'handles flat array of coordinates' do
      pts = [1, 2, 3, 4, 5, 6]
      _(Autocad::Point3d.pts_to_array(pts)).must_equal([1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
    end
  end
end
