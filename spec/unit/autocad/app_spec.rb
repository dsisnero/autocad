# frozen_string_literal: true

require_relative "../../spec_helper"

describe "Autocad::App" do
  include TestHelper
  describe "class methods" do
    after(:all) do
      cleanup_temp_files
    end
    describe "App.run" do
      it "returns an app instance"
      result = nil
      Autocad::App.run do |app|
        puts self
        # expect(app).must_be_instance_of(Autocad::App)
        result = app
        # _(result).must_be_instance_of(Autocad::App)
      end
    end

    describe "App.with_drawings" do
      it "handles batch processing with with_drawings" do
        drawings = [
          fixtures_file("test.dwg"),
          fixtures_file("hello.dwg")
        ]
        test = self

        processed = []
        Autocad::App.with_drawings(drawings) do |drawing|
          _(test.expect(drawing)).must_be_instance_of(Autocad::Drawing) # M
          processed << drawing.path
        end

        _(processed.size).must_equal 2
        _(processed.all? { |p| p.to_s.end_with?(".dwg", ".dgn") }).must_equal true
      end
    end

    it "converts dgn to pdf" do
      drawing = fixtures_file("test.dgn")
      with_test_drawing(drawing) do |path|
        outdir = TEMP_DIR
        Autocad::App.dgn2pdf(path, outdir: outdir, mode: :file)

        pdf_path = outdir.join("test.pdf")
        _(pdf_path.exist?).must_equal true
      end
    end
  end

  describe "an initialized app" do
    before(:all) do
      @app = Autocad::App.new(visible: true)
    end

    after(:all) do
      cleanup_temp_drawings
    end

    it "doesn't have an active_drawing" do
      _(@app.active_drawing).must_be_nil
    end

    it "allows you to create a drawing" do
      name = temp_file("test.dwg")
      drawing = @app.new_drawing(name)
      _(drawing).must_be_instance_of(Autocad::Drawing)
      drawing.close
      cleanup_test_drawing(name)
    end

    it "#templates_path returns a pathname" do
      _(@app.templates_path).must_be_instance_of(Pathname)
    end
    it "can open drawing read_only as class method" do
      drawing_path = fixtures_file("test.dwg")
      with_test_drawing(drawing_path) do |file|
        @app.open_drawing(file, options: {read_only: true}) do |dwg|
          _(dwg).must_be_instance_of Autocad::Drawing
        end
      end
    end

    it "#templates returns an iterator of templates in template_directory" do
      skip
      templates = @app.templates
      _(templates).must_be_instance_of ::Enumerator
      templates { |t| puts t }
    end
    describe "drawing operations" do
    end
  end

  describe "App.run" do
  end
end
