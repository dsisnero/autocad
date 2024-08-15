# frozen_string_literal: true

require_relative "../../spec_helper"

describe Autocad::App do
  describe "an initialized app" do
    before(:all) do
      @app = Autocad::App.new(visible: true)
    end

    after(:all) do
      @app.quit
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

    it "#templates_path returns a pathname" do
      _(@app.templates_path).must_be_instance_of(Pathname)
    end

    it "#templates returns an iterator of templates in template_directory" do
      skip
      templates = @app.templates
      templates.must_be_instance_of ::Enumerator
      templates { |t| puts t }
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
