module Autocad
  class SelectionSetAdapter
    def self.from_ole_obj(drawing, ole)
      ss = SelectionSet.new(ole.Name)
      new(drawing, ss, ole)
    end

    attr_reader :ole_obj, :drawing, :selection_set

    def initialize(drawing, selection_set, ole = nil)
      @drawing = drawing
      @selection_set = selection_set
      @ole_obj = ole || create_selection_set
    end

    def delete
      @ole_obj.Delete
      @selection_set = nil
    end

    # checks if the selection set has any items
    # @ rbs return bool
    def has_items?
      ole_obj.Count > 0
    end

    def count
      ole_obj.Count
    end

    def clear
      ole_obj.Clear
    end

    def filter_text(str)
      @selection_set.filter_text(str)
    end

    def filter_text_containing(str)
      @selection_set.filter_text_containing(str)
    end

    def app
      @drawing.app
    end

    def each
      return to_enum(__callee__) unless block_given?

      ole_obj.each { |o| yield app.wrap(o) }
    end

    def name
      @ole_obj.Name
    end

    def filter_types
      @selection_set.filter_types
    end

    def filter_values
      @selection_set.filter_values
    end

    def select_on_screen(ft = ole_filter_types, fv = ole_filter_values)
      @ole_obj.SelectOnScreen(ft, fv)
    end

    def select(mode: :all, pt1: nil, pt2: nil, ft: ole_filter_types, fv: ole_filter_values)
      acad_mode = case mode
      when :all
        ACAD::AcSelectionSetAll
      when :window
        ACAD::AcSelectionSetWindow
      when :crossing
        ACAD::AcSelectionSetCrossing
      when :previous
        ACAD::AcSelectionSetPrevious
      when :last
        ACAD::AcSelectionSetLast
      else
        Acad::AcSelectionSetAll
      end
      @ole_obj.Select(acad_mode, nil, nil, ft, fv)
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
      @drawing.ole_obj.SelectionSets.Add(@selection_set.name)
    end

    def ole_filter_types
      WIN32OLE::Variant.new(filter_types, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_I2)
    end

    def ole_filter_values
      WIN32OLE::Variant.new(filter_values, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_VARIANT)
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
