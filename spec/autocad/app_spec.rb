# frozen_string_literal: true

require_relative "../test_helper"

describe Autocad::App do
  describe "an initialized app" do
    before do
      @app = Autocad::App.new(visible: true)
    end

    it "doesn't have an active_drawing" do
      _(@app.active_drawing).must_be_nil
    end

    it "allows you to create a drawing" do
      drawing = @app.new_drawing("test.dgn")
      _(drawing).must_be_instance_of(Autocad::Drawing)
      puts drawing.name
      @app.quit
    end

    describe "#get_point" do
      before do
        doc = @app.Documents.Add unless @app.has_documents?
      end

      it "allows you to get points" do
        pt = @app.get_point
        _(pt).must_be_instance_of(Autocad::Point3d)
      end

      it "allows you to change prompt" do
        pt = @app.get_point(prompt: "Please add another point")
        _(pt).must_be_instance_of(Autocad::Point3d)
      end

      it "allows you to change base point" do
        pt = @app.get_point(base_point: [0, 0, 0], prompt: "Get other corner")
        _(pt).must_be_instance_of(Autocad::Point3d)
      end
    end

    describe "ole_doc_get point" do
      before do
        @app.Documents.Add unless @app.has_documents?
      end

      it "allows you to use array for basepoint" do
        skip
        pt = @app.doc_ole.Utility.GetPoint([0, 0, 0], "Get other corner")
        _(pt).must_be_instance_of(Autocad::Point3d)
      end
    end
  end

  describe "App.run" do
    it "call App.new" do
      result = nil
      app = Autocad::App.run do |app|
        _(app).must_be_instance_of(Autocad::App)
        result = app
        _(result).must_be_instance_of(Autocad::App)
      end
    end
  end
end
