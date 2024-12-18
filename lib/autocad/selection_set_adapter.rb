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
      point = if x.respond_to?(:x) && x.respond_to?(:y)
        # Handle Point3d object
        [x.x, x.y]
      elsif x.is_a?(Array)
        # Handle array input
        x
      else
        # Handle separate x,y coordinates
        [x, y]
      end

      @ole_obj.SelectAtPoint(point, filter_types, filter_values)
    end

    # @param points [Array<Point3d>] Array of points defining the polygon
    # @param mode [:fence, :window, :crossing] Selection mode
    def select_by_polygon(points: [], mode: :fence)
      # Convert points to arrays of coordinates
      point_coords = points.map { |p| [p.x, p.y] }

      mode_code = case mode
      when :fence then 5
      when :window then 3
      when :crossing then 4
      else
        raise ArgumentError, "Invalid selection mode: #{mode}. Must be :fence, :window, or :crossing"
      end

      @ole_obj.SelectByPolygon(mode_code, point_coords, filter_types, filter_values)
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
