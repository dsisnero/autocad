module Autocad
  # Manages AutoCAD selection set operations and OLE integration
  #
  # Executes selections using stored criteria and provides access to selected entities.
  # Bridges between Ruby selection criteria and AutoCAD's native selection mechanisms.
  #
  # Key Features:
  # - Multiple selection methods (window, crossing, fence, point)
  # - Filter-based entity selection
  # - Enumeration of selected entities
  # - OLE integration with AutoCAD
  #
  # @example Create and use a selection set
  #   ss = drawing.create_selection_set("walls")
  #   ss.filter { |f| f.layer("WALLS") }
  #   ss.select(mode: :all)
  #   ss.each { |wall| wall.color = 1 }
  class SelectionSetAdapter
    # Initialize from OLE object
    # @param drawing [Drawing] Parent drawing document
    # @param ole [WIN32OLE] AutoCAD OLE selection set object
    # @return [SelectionSetAdapter] New adapter instance
    # @rbs drawing: Drawing
    # @rbs ole: WIN32OLE
    # @rbs return SelectionSetAdapter
    def self.from_ole_obj(drawing, ole)
      ss = SelectionSet.new(ole.Name)
      new(drawing, ss, ole)
    end

    # @rbs attr_reader ole_obj: WIN32OLE -- Underlying OLE selection set
    # @rbs attr_reader drawing: Drawing -- Parent drawing document
    # @rbs attr_reader selection_set: SelectionSet -- Configured selection criteria
    attr_reader :ole_obj, :drawing, :selection_set

    # Initialize new adapter
    # @param drawing [Drawing] Parent drawing document
    # @param selection_set [SelectionSet] Selection criteria container
    # @param ole [WIN32OLE, nil] Optional existing OLE selection set
    # @rbs drawing: Drawing
    # @rbs selection_set: SelectionSet
    # @rbs ole: WIN32OLE?
    # @rbs return void
    def initialize(drawing, selection_set, ole = nil)
      @drawing = drawing
      @selection_set = selection_set
      @ole_obj = ole || create_selection_set
    end

    # Delete the selection set from AutoCAD
    # @return [void]
    # @example Remove selection set when no longer needed
    #   ss.delete if ss.count == 0
    # @rbs return void
    def delete
      @ole_obj.Delete
      @selection_set = nil
    end

    # Checks if the selection set has any items
    # @return [Boolean] True if selection contains entities
    # @example Skip processing if selection is empty
    #   next unless ss.has_items?
    # @rbs return bool
    def has_items?
      ole_obj.Count > 0
    end

    # Get item count in selection set
    # @return [Integer] Number of selected entities
    # @example Report selection count
    #   puts "Selected #{ss.count} entities"
    # @rbs return Integer
    def count
      ole_obj.Count
    end

    # Clear selection set contents
    # @return [void]
    # @example Clear before new selection
    #   ss.clear
    #   ss.select_on_screen
    # @rbs return void
    def clear
      ole_obj.Clear
    end

    # Clear filter criteria
    # @return [void]
    # @example Reset filters for new selection
    #   ss.clear_filter
    #   ss.filter { |f| f.type("LINE") }
    # @rbs return void
    def clear_filter
      selection_set.clear_filter
    end

    # Set text content filter
    # @param str [String] Text pattern to match
    # @return [void]
    # @example Filter for text with specific content
    #   ss.filter_text("Revision")
    # @rbs str: String -- Text pattern to match
    # @rbs return void
    def filter_text(str)
      @selection_set.filter_text(str)
    end

    # Filter text containing substring
    # @param str [String] Substring to match
    # @return [void]
    # @example Find text containing "NOTE"
    #   ss.filter_text_containing("NOTE")
    # @rbs str: String -- Substring to match
    # @rbs return void
    def filter_text_containing(str)
      @selection_set.filter_text_containing(str)
    end

    # Get the application instance
    # @return [Autocad::App] The application instance
    # @private
    def app
      @drawing.app
    end

    # Iterate through selected entities
    # @yield [Element] Block to process each entity
    # @return [Enumerator<Element>] Enumerator of selected entities if no block given
    # @example Process each selected entity
    #   ss.each { |entity| entity.color = 1 }
    # @example Convert to array
    #   entities = ss.each.to_a
    # @rbs &: (Element) -> void
    # @rbs return Enumerator[Element]
    def each
      return to_enum(__callee__) unless block_given?

      ole_obj.each { |o| yield app.wrap(o) }
    end

    # Get the name of the selection set
    # @return [String] The selection set name
    # @example Get selection set identifier
    #   puts "Working with selection set: #{ss.name}"
    # @rbs return String
    def name
      @ole_obj.Name
    end

    # Get filter types from selection set
    # @return [Array<Integer>] Array of DXF group codes
    # @example Access raw filter data
    #   puts "Using filter types: #{ss.filter_types.join(', ')}"
    # @rbs return Array[Integer]
    def filter_types
      @selection_set.filter_types
    end

    # Get filter values from selection set
    # @return [Array<Object>] Array of filter values
    # @example Access raw filter data
    #   puts "Using filter values: #{ss.filter_values.inspect}"
    # @rbs return Array[untyped]
    def filter_values
      @selection_set.filter_values
    end

    # Select entities interactively on screen
    # @param ft [WIN32OLE::Variant, nil] Optional filter types variant
    # @param fv [WIN32OLE::Variant, nil] Optional filter values variant
    # @return [void]
    # @example Select entities with user interaction
    #   ss.select_on_screen
    # @example Select with predefined filters
    #   ss.filter { |f| f.type("CIRCLE") }
    #   ss.select_on_screen
    # @rbs ft: WIN32OLE::Variant? -- Filter types variant
    # @rbs fv: WIN32OLE::Variant? -- Filter values variant
    # @rbs return void
    def select_on_screen(ft = ole_filter_types, fv = ole_filter_values)
      if filter_types.empty? && filter_values.empty?
        @ole_obj.SelectOnScreen(nil, nil)
      else
        @ole_obj.SelectOnScreen(ft, fv)
      end
    end

    # Select entities using various methods
    # @param mode [Symbol] Selection mode (:all, :window, :crossing, :previous, :last)
    # @param pt1 [Point3d, nil] First point for window selection
    # @param pt2 [Point3d, nil] Second point for window selection
    # @param ft [WIN32OLE::Variant, nil] Optional filter types variant
    # @param fv [WIN32OLE::Variant, nil] Optional filter values variant
    # @return [void]
    # @example Select all entities matching filter
    #   ss.select(mode: :all)
    # @example Window selection
    #   ss.select(mode: :window, pt1: [0,0,0], pt2: [10,10,0])
    # @rbs mode: Symbol -- Selection mode (:all, :window, :crossing, :previous, :last)
    # @rbs pt1: Point3d? -- First point for window selection
    # @rbs pt2: Point3d? -- Second point for window selection
    # @rbs ft: WIN32OLE::Variant? -- Filter types variant
    # @rbs fv: WIN32OLE::Variant? -- Filter values variant
    # @rbs return void
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
    rescue => ex
      binding.irb
    end

    # Select entities at specific point
    # @param x [Numeric, Point3d, Array<Numeric>] X coordinate or point object
    # @param y [Numeric, nil] Y coordinate (if using separate coordinates)
    # @return [void]
    # @example Select at specific point
    #   ss.select_at_point(10, 20)
    # @example Select at point object
    #   ss.select_at_point(Point3d.new(10, 20, 0))
    # @rbs x: Numeric | Point3d | Array[Numeric] -- X coordinate or point object
    # @rbs y: Numeric? -- Y coordinate (if using separate coordinates)
    # @rbs return void
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

    # Select entities using polygonal fence
    # @param points [Array<Point3d>] Polygon vertices
    # @param mode [Symbol] Selection mode (:fence, :window, :crossing)
    # @return [void]
    # @raise [ArgumentError] For invalid mode
    # @example Select using fence
    #   points = [[0,0], [10,0], [10,10], [0,10]]
    #   ss.select_by_polygon(points: points, mode: :fence)
    # @rbs points: Array[Point3d] -- Polygon vertices
    # @rbs mode: Symbol -- Selection mode (:fence, :window, :crossing)
    # @rbs return void
    # @raise [ArgumentError] For invalid mode
    def select_by_polygon(points: [], mode: :fence)
      # Convert points to arrays of coordinates
      point_coords = points.map { |p| Point3d(p) }.map { |p| [p.x, p.y, p.z] }.flatten

      mode_code = case mode
      when :fence then 5
      when :window then 3
      when :crossing then 4
      else
        raise ArgumentError, "Invalid selection mode: #{mode}. Must be :fence, :window, or :crossing"
      end
      ole_point_coords = WIN32OLE::Variant.new(point_coords, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)

      binding.irb
      @ole_obj.SelectByPolygon(mode_code, ole_point_coords, filter_types, filter_values)
    end

    # Configure filter through block
    # @yield [Filter] Block for building filter criteria
    # @return [void]
    # @example Create complex filter
    #   ss.filter do |f|
    #     f.and(f.layer("WALLS"), f.or(f.type("LINE"), f.type("POLYLINE")))
    #   end
    # @rbs &: (Filter) -> Filter
    # @rbs return void
    def filter(&)
      @selection_set.filter(&)
    end

    private

    # Create new OLE selection set
    # @return [WIN32OLE] The created OLE selection set
    # @rbs return WIN32OLE
    def create_selection_set
      @drawing.ole_obj.SelectionSets.Add(@selection_set.name)
    end

    # Convert filter types to OLE variant
    # @return [WIN32OLE::Variant] OLE variant for filter types
    # @rbs return WIN32OLE::Variant
    def ole_filter_types
      WIN32OLE::Variant.new(filter_types, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_I2)
    end

    # Convert filter values to OLE variant
    # @return [WIN32OLE::Variant] OLE variant for filter values
    # @rbs return WIN32OLE::Variant
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
