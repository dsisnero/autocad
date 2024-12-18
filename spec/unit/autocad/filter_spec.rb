require_relative '../../spec_helper'

describe Autocad::Filter do
  let(:filter) { Autocad::Filter.new }

  describe 'initialization' do
    it 'starts with empty types and values' do
      _(filter.types).must_be_empty
      _(filter.values).must_be_empty
      _(filter.has_filters?).must_equal false
    end
  end

  describe 'basic operations' do
    it 'creates type filter' do
      my_filter = filter.type('Circle')
      types, values = my_filter.convert_clauses
      _(types).must_equal [0]
      _(values).must_equal ['Circle']
    end

    it 'creates layer filter' do
      my_filter = filter.layer('0')
      types, values = my_filter.convert_clauses
      _(types).must_equal [8]
      _(values).must_equal ['0']
    end

    it 'creates color filter' do
      my_filter = filter.color(1)
      types, values = my_filter.convert_clauses
      _(types).must_equal [62]
      _(values).must_equal [1]
    end
  end

  describe 'compound operations' do
    it 'creates OR filter' do
      circle = filter.type('Circle')
      arc = filter.type('Arc')

      result = filter.or(circle, arc)
      types, values = result.convert_clauses

      _(types).must_equal [-4, 0, 0, -4]
      _(values).must_equal ['<OR', 'Circle', 'Arc', 'OR>']
    end

    it 'creates AND filter' do
      circle = filter.type('Circle')
      layer = filter.layer('0')
      color = filter.color(1)

      result = filter.and(circle, layer, color)
      types, values = result.convert_clauses

      _(types).must_equal [-4, 0, 8, 62, -4]
      _(values).must_equal ['<AND', 'Circle', '0', 1, 'AND>']
    end

    it 'creates XOR filter' do
      circle = filter.type('Circle')
      arc = filter.type('Arc')

      result = filter.xor(circle, arc)
      types, values = result.convert_clauses

      _(types).must_equal [-4, 0, 0, -4]
      _(values).must_equal ['<XOR', 'Circle', 'Arc', 'XOR>']
    end

    it 'creates NOT filter' do
      circle = filter.type('Circle')

      result = filter.not(circle)
      types, values = result.convert_clauses

      _(types).must_equal [-4, 0, -4]
      _(values).must_equal ['<NOT', 'Circle', 'NOT>']
    end

    it 'creates complex nested filter' do
      # (Circle OR Arc) AND Layer0 AND Color1
      circle_or_arc = filter.or(
        filter.type('Circle'),
        filter.type('Arc')
      )
      layer = filter.layer('0')
      color = filter.color(1)

      result = filter.and(circle_or_arc, layer, color)
      types, values = result.convert_clauses

      expected_types = [-4, -4, 0, 0, -4, 8, 62, -4]
      expected_values = ['<AND', '<OR', 'Circle', 'Arc', 'OR>', '0', 1, 'AND>']

      _(types).must_equal expected_types
      _(values).must_equal expected_values
    end
  end

  describe 'relational operations' do
    it 'creates greater than filter' do
      result = filter.greater_than(5)
      types, values = result.convert_clauses
      _(types).must_equal [-4, 40]
      _(values).must_equal ['>=', 5]
    end

    it 'creates less than filter' do
      result = filter.less_than(5)
      types, values = result.convert_clauses
      _(types).must_equal [-4, 40]
      _(values).must_equal ['<=', 5]
    end

    it 'creates equal to filter' do
      result = filter.equal_to(5)
      types, values = result.convert_clauses
      _(types).must_equal [-4, 40]
      _(values).must_equal ['=', 5]
    end
  end

  describe 'special filters' do
    it 'creates block reference filter' do
      result = filter.block_reference
      types, values = result.convert_clauses
      _(types).must_equal [0]
      _(values).must_equal ['INSERT']
    end

    it 'creates contains text filter' do
      result = filter.contains('test')
      types, values = result.convert_clauses
      _(types).must_equal [-4, 1, 1, -4]
      _(values).must_equal ['<OR', '*test*', '*test*', 'OR>']
    end

    it 'creates space filters' do
      model = filter.model_space
      types, values = model.convert_clauses
      _(types).must_equal [67]
      _(values).must_equal [0]

      paper = filter.paper_space
      types, values = paper.convert_clauses
      _(types).must_equal [67]
      _(values).must_equal [1]
    end
  end
end
