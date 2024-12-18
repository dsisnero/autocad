require_relative '../../spec_helper'

describe Autocad::SelectionSet do
  describe 'new selection_set' do
    let(:ss) { Autocad::SelectionSet.new('test_ss') }

    it 'has a name' do
      _(ss.name).must_equal 'test_ss'
    end

    describe '#filter' do
      it 'creates correct filter for circle or arc' do
        ss.filter do |f|
          f.type('Circle').or(f.type('Arc'))
        end
        
        _(ss.filter_types).must_equal([-4, 0, 0, -4])
        _(ss.filter_values).must_equal(['<OR', 'Circle', 'Arc', 'OR>'])
      end

      it 'creates correct filter for text search' do
        ss.filter_text('*The*')
        
        _(ss.filter_types).must_equal([-4, 0, 0, -4])
        _(ss.filter_values).must_equal(['<OR', 'TEXT', 'MTEXT', 'OR>'])
      end

      it 'creates correct filter for block reference' do
        ss.filter do |f|
          f.block_reference
        end
        
        _(ss.filter_types).must_equal([0])
        _(ss.filter_values).must_equal(['INSERT'])
      end

      it 'creates correct filter with not operator' do
        ss.filter do |f|
          f.not(
            f.type('Circle').or(f.type('Arc'))
          )
        end
        
        _(ss.filter_types).must_equal([-4, -4, 0, 0, -4, -4])
        _(ss.filter_values).must_equal(['<NOT', '<OR', 'Circle', 'Arc', 'OR>', 'NOT>'])
      end

      it 'combines multiple conditions' do
        ss.filter do |f|
          f.and(
            f.type('Circle'),
            f.layer('0'),
            f.color(1)
          )
        end
        
        _(ss.filter_types).must_equal([-4, 0, 8, 62, -4])
        _(ss.filter_values).must_equal(['<AND', 'Circle', '0', 1, 'AND>'])
      end
    end
  end
end
