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

    it "#selection_sets should return an enumerator when no block given" do
      _(drawing.selection_sets).must_be_kind_of(Enumerator)
    end

    it "#selection_sets should yield selection sets when block given" do
      sets = []
      drawing.selection_sets { |set| sets << set }
      sets.each do |set|
        _(set).must_be_instance_of(Autocad::SelectionSetAdapter)
      end
    end

    describe "#create_selection_set" do
      it "must create a selection set" do
        ss = drawing.selection_sets.find { |s| s.name == "test" }
        _(ss).must_be_nil
        drawing.create_selection_set("test")
        ss = drawing.selection_sets.find { |s| s.name == "test" }

        _(ss).must_be_kind_of Autocad::SelectionSetAdapter
        _(ss.name).must_equal "test"
      end
    end

    describe "#get_variables" do
      it "returns an  array with the variable current values" do
        vars = drawing.get_variables("nomutt", "clayer", "textstyle")
        _(vars).must_be_kind_of(Array)
        _(vars.size).must_equal 3
      end

      it "can accept an array of variable names" do
        vars = drawing.get_variables(%w[nomutt clayer textstyle])
        _(vars).must_be_kind_of(Array)
        _(vars.size).must_equal 3
      end
    end

    describe "#set_variables" do
      it "sets system variables" do
        names = %w[nomutt clayer textstyle]
        values = drawing.get_variables(names)

        drawing.set_variables(names, [0, "0", "STANDARD"])
        values2 = drawing.get_variables(names)

        _(values).wont_equal(values2)
        _(values2).must_equal([0, "0", "STANDARD"])
        drawing.set_variables(names, values)
      end
    end

    describe "#linetypes" do
      it "returns an enumerator when no block given" do
        _(drawing.linetypes).must_be_kind_of(Enumerator)
      end

      it "yields linetypes when block given" do
        types = []
        drawing.linetypes { |lt| types << lt }
        _(types).wont_be_empty
        types.each do |lt|
          _(lt).must_be_kind_of(Autocad::Linetype)
        end
      end
    end
    describe "#layouts" do
      it "returns an enumerator when no block given" do
        _(drawing.layouts).must_be_kind_of(Enumerator)
      end

      it "yields layouts when block given" do
        types = []
        drawing.layouts { |lt| types << lt }
        _(types).wont_be_empty
        types.each do |lt|
          _(lt).must_be_kind_of(Autocad::Layout)
        end
      end
    end
    describe "#plot_configurations" do
      it "returns an enumerator when no block given" do
        _(drawing.plot_configurations).must_be_kind_of(Enumerator)
      end

      it "yields PlotConfigurations when block given" do
        types = []

        drawing.plot_configurations { |lt| types << lt }

        _(types).wont_be_empty

        types.each do |lt|
          _(lt).must_be_kind_of(Autocad::PlotConfiguration)
        end
      end
    end
  end
end
