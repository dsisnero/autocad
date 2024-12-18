module Autocad
  class SelectionSetAdapter
    def initialize(drawing, selection_set)
      @drawing = drawing
      @selection_set = selection_set
      @ole_obj = create_selection_set
    end

    def filter_types
      @selection_set.to_ole_filter_type
    end

    def filter_values
      @selection_set.to_ole_filter_value
    end

    def select_on_screen
      @ole_obj.SelectOnScreen(filter_types, filter_values)
    end

    # accepts Point3d | [x,y] | (x,y)
    def select_at_point(x, y)
      @ole_obj.SelectAtPoint(x, y, filter_types, filter_values)
    end

    # @rbs mode: :fence | :window | :crossing -
    # @rbs points: Array[Point3d]
    def select_by_polygon(points: [], mode: :fence)
    end

    def filter(&)
      @selection_set.filter(&)
    end

    private

    def create_selection_set
      ole_obj = @drawing.ole_obj.SelectionSets.Add(@selection_set.name)
    end

    def create_ole_variant(data)
      return nil unless data

      if data.first.is_a?(Integer)
        WIN32OLE::VARIANT.new(data, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_I2)
      else
        WIN32OLE::VARIANT.new(data, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_VARIANT)
      end
    end
  end
end

# ss = Autocad::SelectionSet.new('test_ss')
# ss.filter_text_containing('test')
# ss = drawing.create_selection_set('test_ss') do
#    filter do |f|
#      f.or(f.type('Circle'), f.type('Arc'))
#    end
# end
