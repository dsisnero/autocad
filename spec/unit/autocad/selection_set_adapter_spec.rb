require_relative '../../spec_helper'

describe Autocad::SelectionSetAdapter do
  let(:drawing) { Minitest::Mock.new }
  let(:selection_set) { Autocad::SelectionSet.new('test_ss') }
  let(:ole_selection_sets) { Minitest::Mock.new }
  let(:ole_selection_set) { Minitest::Mock.new }
  let(:adapter) { Autocad::SelectionSetAdapter.new(drawing, selection_set) }

  before do
    drawing.expect(:ole_obj, OpenStruct.new(SelectionSets: ole_selection_sets))
    ole_selection_sets.expect(:Add, ole_selection_set, ['test_ss'])
  end

  describe '#select_at_point' do
    it 'handles Point3d input' do
      point = OpenStruct.new(x: 1.0, y: 2.0)
      ole_selection_set.expect(:SelectAtPoint, nil, [[1.0, 2.0], nil, nil])
      
      adapter.select_at_point(point)
      ole_selection_set.verify
    end

    it 'handles array input' do
      ole_selection_set.expect(:SelectAtPoint, nil, [[3.0, 4.0], nil, nil])
      
      adapter.select_at_point([3.0, 4.0])
      ole_selection_set.verify
    end

    it 'handles coordinate input' do
      ole_selection_set.expect(:SelectAtPoint, nil, [[5.0, 6.0], nil, nil])
      
      adapter.select_at_point(5.0, 6.0)
      ole_selection_set.verify
    end
  end

  describe '#select_by_polygon' do
    let(:points) do
      [
        OpenStruct.new(x: 0.0, y: 0.0),
        OpenStruct.new(x: 1.0, y: 0.0),
        OpenStruct.new(x: 1.0, y: 1.0),
        OpenStruct.new(x: 0.0, y: 1.0)
      ]
    end

    let(:point_coords) { [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]] }

    it 'handles fence selection' do
      ole_selection_set.expect(:SelectByPolygon, nil, [5, point_coords, nil, nil])
      
      adapter.select_by_polygon(points: points, mode: :fence)
      ole_selection_set.verify
    end

    it 'handles window selection' do
      ole_selection_set.expect(:SelectByPolygon, nil, [3, point_coords, nil, nil])
      
      adapter.select_by_polygon(points: points, mode: :window)
      ole_selection_set.verify
    end

    it 'handles crossing selection' do
      ole_selection_set.expect(:SelectByPolygon, nil, [4, point_coords, nil, nil])
      
      adapter.select_by_polygon(points: points, mode: :crossing)
      ole_selection_set.verify
    end

    it 'raises error for invalid mode' do
      _(proc {
        adapter.select_by_polygon(points: points, mode: :invalid)
      }).must_raise ArgumentError
    end
  end
end
