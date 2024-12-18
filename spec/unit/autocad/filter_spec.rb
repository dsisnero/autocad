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
      filter = Autocad::Filter.new
      my_filter = filter.type('Circle')
      _(my_filter.types).must_equal [0]
      _(my_filter.values).must_equal ['Circle']
    end

    it 'creates layer filter' do
      my_filter = filter.layer('0')
      _(my_filter.types).must_equal [8]
      _(my_filter.values).must_equal ['0']
    end

    it 'creates color filter' do
      my_filter = filter.color(1)
      _(my_filter.types).must_equal [62]
      _(my_filter.values).must_equal [1]
    end
  end

  describe 'compound operations' do
    it 'creates OR filter' do
      circle = filter.new.type('Circle')
      arc = filter.new.type('Arc')

      result = filter.or(circle, arc)

      _(result.types).must_equal [-4, 0, 0, -4]
      _(result.values).must_equal ['<OR', 'Circle', 'Arc', 'OR>']
    end

    it 'creates AND filter' do
      circle = filter.type('Circle')
      layer = filter.layer('0')
      color = filter.color(1)

      result = filter.and(circle, layer, color)

      _(result.types).must_equal [-4, 0, 8, 62, -4]
      _(result.values).must_equal ['<AND', 'Circle', '0', 1, 'AND>']
    end

    it 'creates XOR filter' do
      circle = filter.type('Circle')
      arc = filter.type('Arc')

      result = filter.xor(circle, arc)

      _(result.types).must_equal [-4, 0, 0, -4]
      _(result.values).must_equal ['<XOR', 'Circle', 'Arc', 'XOR>']
    end

    it 'creates NOT filter' do
      circle = filter.type('Circle')

      result = filter.not(circle)

      _(result.types).must_equal [-4, 0, -4]
      _(result.values).must_equal ['<NOT', 'Circle', 'NOT>']
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

      expected_types = [-4, -4, 0, 0, -4, 8, 62, -4]
      expected_values = ['<AND', '<OR', 'Circle', 'Arc', 'OR>', '0', 1, 'AND>']

      _(result.types).must_equal expected_types
      _(result.values).must_equal expected_values
    end
  end

  describe 'relational operations' do
    it 'creates greater than filter' do
      filter.greater_than(5)
      _(filter.types).must_equal [-4, 40]
      _(filter.values).must_equal ['>=', 5]
    end

    it 'creates less than filter' do
      filter.less_than(5)
      _(filter.types).must_equal [-4, 40]
      _(filter.values).must_equal ['<=', 5]
    end

    it 'creates equal to filter' do
      filter.equal_to(5)
      _(filter.types).must_equal [-4, 40]
      _(filter.values).must_equal ['=', 5]
    end
  end

  describe 'special filters' do
    it 'creates block reference filter' do
      filter.block_reference
      _(filter.types).must_equal [0]
      _(filter.values).must_equal ['INSERT']
    end

    it 'creates contains text filter' do
      filter.contains('test')
      _(filter.types).must_equal [-4, 1, 1, -4]
      _(filter.values).must_equal ['<OR', '*test*', '*test*', 'OR>']
    end

    it 'creates space filters' do
      model = filter.model_space
      _(model.types).must_equal [67]
      _(model.values).must_equal [0]

      paper = filter.paper_space
      _(paper.types).must_equal [67]
      _(paper.values).must_equal [1]
    end
  end
end
