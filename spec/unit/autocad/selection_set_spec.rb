require_relative '../../spec_helper'

describe Autocad::SelectionSet do
  before(:all) do
    @app = Autocad::App.new
  end

  after(:all) do
    @app.quit
  end

  describe 'given a drawing exists' do
    let(:path) { 'ss_drawing.dwg' }
    after do
      drawing&.close(save: false)
      File.delete(path) if File.exist? path
    end

    let(:drawing) { @app.new_drawing(path) }

    describe 'new selection_set' do
      let(:ss) { drawing.create_selection_set('test_ss') }

      it 'has a name' do
        _(ss.name).must_equal 'test_ss'
      end

      it 'has a filter method' do
        ss.filter do |f|
          f.type('Circle').or(f.type('Arc'))
        end
        _(ss.filter_types).must_equal([-4, 0, 0, -4])
        _(ss.filter_values).must_equal(['<OR', 'Circle', 'Arc', 'OR>'])
      end

      it 'can filter block reference' do
        ss.filter do |f|
          f.block_reference
        end
        _(ss.filter_types).must_equal([0])
        _(ss.filter_values).must_equal(['INSERT'])
      end

      it 'has a not operator' do
        ss.filter do |f|
          f.not(
            f.type('Circle').or(f.type('Arc'))
          )
        end
        _(ss.filter_types).must_equal([-4, -4, 0, 0, -4, -4])
        _(ss.filter_values).must_equal(['<NOT', '<OR', 'Circle', 'Arc', 'OR>', 'NOT>'])
      end
    end
  end
end
