require_relative "../../spec_helper"

describe Autocad::Drawing do
  before(:all) do
    @app = Autocad::App.new
  end

  after(:all) do
    @app.quit
  end

  describe "when using a new drawing" do
    after do
      path = drawing&.path
      drawing&.close(save: false)
      File.delete(path) if File.exist? path
    end

    let(:drawing) { @app.new_drawing("test.dwg") }

    it "#path should return a pathname" do
      _(drawing.path).must_be_instance_of(Pathname)
    end

    it "#active_space should return the correct model" do
      drawing.to_model_space
      _(drawing.active_space).must_be_instance_of(Autocad::ModelSpace)
      drawing.to_paper_space
      _(drawing.active_space).must_be_instance_of(Autocad::PaperSpace)
    end
  end
end
