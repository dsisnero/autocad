# frozen_string_literal: true

require_relative "../../spec_helper"

describe "Autocad::Element" do
  include TestHelper

  before(:all) do
    @app = Autocad::App.new(visible: false)
    @drawing = @app.new_drawing(temp_file("element_test.dwg"))
    @model_space = @drawing.model_space
  end

  after(:all) do
    @drawing.close(false)
    cleanup_temp_files
  end

  describe "#bounds" do
    describe "for a circle" do
      it "returns correct bounding box" do
        center = Autocad::Point3d.new(50, 50, 0)
        radius = 25.0
        circle = @model_space.add_circle(center, radius)
        bounds = circle.bounds

        # Circle with radius 25 at (50,50) should have bounds:
        # min: (25,25,0) max: (75,75,0)
        _(bounds.left).must_equal 25.0
        _(bounds.right).must_equal 75.0
        _(bounds.bottom).must_equal 25.0
        _(bounds.top).must_equal 75.0
        _(bounds.width).must_equal 50.0
        _(bounds.height).must_equal 50.0
      end
    end
  end

  describe "#bounds" do
    describe "for a line" do
      it "returns correct bounding box" do
        pt1 = Autocad::Point3d.new(0, 0, 0)
        pt2 = Autocad::Point3d.new(100, 100, 0)
        line = @model_space.add_line(pt1, pt2)
        bounds = line.bounds

        # Circle with radius 25 at (50,50) should have bounds:
        # min: (25,25,0) max: (75,75,0)
        _(bounds.left).must_equal 0.0
        _(bounds.right).must_equal 100.0
        _(bounds.bottom).must_equal 0.0
        _(bounds.top).must_equal 100.0
        _(bounds.width).must_equal 100.0
        _(bounds.height).must_equal 100.0
      end
    end
  end
  describe "for a rectangle" do
    it "returns correct bounding box" do
      upper_left = Autocad::Point3d.new(0, 100, 0)
      lower_right = Autocad::Point3d.new(100, 0, 0)
      rectangle = @model_space.add_rectangle(upper_left, lower_right)
      bounds = rectangle.bounds

      _(bounds.left).must_equal 0.0
      _(bounds.right).must_equal 100.0
      _(bounds.bottom).must_equal 0.0
      _(bounds.top).must_equal 100.0
      _(bounds.width).must_equal 100.0
      _(bounds.height).must_equal 100.0
    end
  end

  describe "for complex shapes" do
    it "correctly calculates bounds for multiple objects" do
      # Create a circle and a rectangle that overlap
      circle = @model_space.add_circle(Autocad::Point3d.new(50, 50, 0), 25.0)
      rectangle = @model_space.add_rectangle([0, 0], [100, 100])

      circle_bounds = circle.bounds
      rect_bounds = rectangle.bounds

      # Verify individual bounds
      _(circle_bounds.width).must_equal 50.0
      _(circle_bounds.height).must_equal 50.0
      _(rect_bounds.width).must_equal 100.0
      _(rect_bounds.height).must_equal 100.0

      # Verify bounds are different
      _(circle_bounds).wont_equal rect_bounds
    end
  end
end

# end
