require_relative '../../spec_helper'

describe Autocad::Drawing do
  before(:all) do
    @app = Autocad::App.new
  end

  after(:all) do
    @app.quit
  end

  describe 'when using a new drawing' do
    after do
      path = drawing&.path
      drawing&.close(save: false)
      File.delete(path) if File.exist? path
    end

    let(:drawing) { @app.new_drawing('test.dwg') }

    it '#path should return a pathname' do
      _(drawing.path).must_be_instance_of(Pathname)
    end

    it '#active_space should return the correct model' do
      drawing.to_model_space
      _(drawing.active_space).must_be_instance_of(Autocad::ModelSpace)
      drawing.to_paper_space
      _(drawing.active_space).must_be_instance_of(Autocad::PaperSpace)
    end

    it '#selection_sets should return an enumerator when no block given' do
      _(drawing.selection_sets).must_be_kind_of(Enumerator)
    end

    it '#selection_sets should yield selection sets when block given' do
      sets = []
      drawing.selection_sets { |set| sets << set }
      sets.each do |set|
        _(set).must_be_instance_of(Autocad::SelectionSet)
      end
    end

    describe '#create_selection_set' do
      it 'must create a selection set' do
        ss = drawing.create_selection_set('test')

        _(ss).must_be_kind_of Autocad::SelectionSet
        _(ss.name).must_equal 'test'
      end
    end

    describe '#linetypes' do
      it 'returns an enumerator when no block given' do
        _(drawing.linetypes).must_be_kind_of(Enumerator)
      end

      it 'yields linetypes when block given' do
        types = []
        drawing.linetypes { |lt| types << lt }
        _(types).wont_be_empty
        types.each do |lt|
          _(lt).must_be_kind_of(Autocad::Linetype)
        end
      end
    end
  end
end
