require_relative "../../spec_helper"

describe Autocad::App do
  before(:all) do
    @app = Autocad::App.new(visible: true)
  end

  after(:all) do
    @app.quit
  end

  describe "#get_point" do
    before do
      @app.Documents.Add unless @app.has_documents?
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
