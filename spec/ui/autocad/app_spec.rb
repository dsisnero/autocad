# frozen_string_literal
require_relative "../../spec_helper"

describe Autocad::App do
  before(:all) do
    @app = Autocad::App.new(visible: true)
  end

  after(:all) do
    @app.quit
  end

  let(:fixtures_dir) { Pathname.new(__dir__).join("../fixtures").expand_path }
  
  describe "drawing operations" do
    it "can open drawing read_only as class method" do
      drawing_path = fixtures_dir.join("test.dwg")
      app.open_drawing(drawing_path, options: { read_only: true }) do |dwg|
        _(dwg).must_be_instance_of Autocad::Drawing
      end
    end

    it "handles batch processing with with_drawings" do
      drawings = [
        fixtures_dir.join("test.dwg"),
        fixtures_dir.join("test.dgn")
      ]
      
      processed = []
      Autocad::App.with_drawings(drawings) do |drawing|
        processed << drawing.path
      end
      
      _(processed.size).must_equal 2
      _(processed.all? { |p| p.to_s.end_with?(".dwg", ".dgn") }).must_equal true
    end

    it "converts dgn to pdf" do
      Dir.mktmpdir do |dir|
        outdir = Pathname.new(dir)
        source = fixtures_dir.join("test.dgn")
        
        Autocad::App.dgn2pdf(source, outdir: outdir, mode: :file)
        
        pdf_path = outdir.join("test.pdf")
        _(pdf_path.exist?).must_equal true
      end
    end
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
