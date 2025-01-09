# frozen_string_literal: true

require_relative "../../spec_helper"

describe "Autocad::BoundingBox" do
  describe ".empty" do
    it "creates an empty bounding box at origin" do
      box = Autocad::BoundingBox.empty

      _(box.left).must_equal 0
      _(box.top).must_equal 0
      _(box.right).must_equal 0
      _(box.bottom).must_equal 0
      _(box.width).must_equal 0
      _(box.height).must_equal 0
    end
  end

  describe ".centered" do
    it "creates a centered bounding box with given dimensions" do
      box = Autocad::BoundingBox.centered(100, 50)

      _(box.left).must_equal(-50)
      _(box.top).must_equal 25
      _(box.right).must_equal 50
      _(box.bottom).must_equal(-25)
      _(box.width).must_equal 100
      _(box.height).must_equal 50
    end
  end

  describe ".from_min_max" do
    it "creates a bounding box from min and max points" do
      min_pt = Autocad::Point3d.new(0, 0, 0)
      max_pt = Autocad::Point3d.new(100, 100, 0)
      box = Autocad::BoundingBox.from_min_max(min_pt, max_pt)

      _(box.left).must_equal 0
      _(box.top).must_equal 100
      _(box.right).must_equal 100
      _(box.bottom).must_equal 0
      _(box.width).must_equal 100
      _(box.height).must_equal 100
    end

    it "handles negative coordinates" do
      min_pt = Autocad::Point3d.new(-50, -50, 0)
      max_pt = Autocad::Point3d.new(50, 50, 0)
      box = Autocad::BoundingBox.from_min_max(min_pt, max_pt)

      _(box.left).must_equal(-50)
      _(box.top).must_equal 50
      _(box.right).must_equal 50
      _(box.bottom).must_equal(-50)
      _(box.width).must_equal 100
      _(box.height).must_equal 100
    end
  end

  describe "#enclose" do
    it "expands bounding box to include given point" do
      box = Autocad::BoundingBox.empty
      point = Autocad::Point3d.new(100, 100, 0)
      expanded = box.enclose(point)

      _(expanded.left).must_equal 0
      _(expanded.top).must_equal 100
      _(expanded.right).must_equal 100
      _(expanded.bottom).must_equal 0
    end
  end

  describe "#expand" do
    it "expands bounding box by given amount in all directions" do
      box = Autocad::BoundingBox.centered(100, 100)
      expanded = box.expand(10)

      _(expanded.left).must_equal(-60)
      _(expanded.top).must_equal 60
      _(expanded.right).must_equal 60
      _(expanded.bottom).must_equal(-60)
    end
  end
end
