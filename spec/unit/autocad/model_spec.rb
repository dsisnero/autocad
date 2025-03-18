# frozen_string_literal: true

require_relative "../../spec_helper"

describe "Autocad::Model" do
  include TestHelper

  before(:all) do
    @app = Autocad::App.new(visible: false)
    @drawing = @app.new_drawing(temp_file("model_test.dwg"))
    @model_space = @drawing.model_space
  end

  after(:all) do
    @drawing.close(false)
    cleanup_temp_files
  end

  describe "ModelTrait" do
    describe "#each" do
      it "returns an enumerator when no block given" do
        enum = @model_space.each
        _(enum).must_be_kind_of Enumerator
      end

      it "yields elements when block given" do
        # Add a line to have something to enumerate
        pt1 = Autocad::Point3d.new(0, 0, 0)
        pt2 = Autocad::Point3d.new(100, 100, 0)
        @model_space.add_line(pt1, pt2)

        elements = []
        @model_space.each do |element|
          elements << element
        end

        _(elements).wont_be_empty
        _(elements.first).must_be_kind_of Autocad::Element
      end
    end

    describe "#add_line" do
      it "creates a line between two points" do
        pt1 = Autocad::Point3d.new(0, 0, 0)
        pt2 = Autocad::Point3d.new(100, 100, 0)
        line = @model_space.add_line(pt1, pt2)

        _(line).must_be_kind_of Autocad::Line
      end

      it "creates a line with specified layer" do
        pt1 = Autocad::Point3d.new(0, 0, 0)
        pt2 = Autocad::Point3d.new(100, 100, 0)
        layer_name = "TestLayer"
        line = @model_space.add_line(pt1, pt2, layer: layer_name)

        _(line.layer).must_equal layer_name
      end
    end

    describe "#add_circle" do
      it "creates a circle with center and radius" do
        center = Autocad::Point3d.new(50, 50, 0)
        radius = 25.0
        circle = @model_space.add_circle(center, radius)
        bounds = circle.bounds
        binding.irb

        _(circle).must_be_kind_of Autocad::Circle
      _(bounds).must_equal [Autocad::Point3d.new(25, 25, 0), Autocad::Point3d.new(75, 75, 0)]
      end
    end

    describe "#add_rectangle" do
      it "creates a rectangle from upper left and lower right points" do
        upper_left = Autocad::Point3d.new(0, 100, 0)
        lower_right = Autocad::Point3d.new(100, 0, 0)
        rectangle = @model_space.add_rectangle(upper_left, lower_right)

        _(rectangle).must_be_kind_of Autocad::Element
      end
    end

    describe "#add_spline" do
      it "creates a spline through given points with tangents" do
        points = [
          Autocad::Point3d.new(0, 0, 0),
          Autocad::Point3d.new(50, 50, 0),
          Autocad::Point3d.new(100, 0, 0)
        ]
        start_tangent = Autocad::Point3d.new(1, 0, 0)
        end_tangent = Autocad::Point3d.new(1, 0, 0)
        
        spline = @model_space.add_spline(points, start_tangent, end_tangent)

        _(spline).must_be_kind_of Autocad::Element
      end
    end
  end

  describe "PaperSpace" do
    before do
      @paper_space = @drawing.paper_space
    end

    describe "#add_pv_viewport" do
      it "creates a paper space viewport" do
        point = Autocad::Point3d.new(0, 0, 0)
        viewport = @paper_space.add_pv_viewport(point, width: 100, height: 100)

        _(viewport).must_be_kind_of Autocad::Element
      end
    end
  end

  describe "ModelSpace" do
    it "includes ModelTrait" do
      _(Autocad::ModelSpace.included_modules).must_include Autocad::ModelTrait
    end

    it "is an Element" do
      _(@model_space).must_be_kind_of Autocad::Element
    end
  end

end
