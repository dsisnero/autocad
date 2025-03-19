module Autocad
  class Spline < Element
    # @rbs return float -- The area of the arc
    def area
      @ole_obj.Area
    end

    # whether the spline is closed
    def closed? # : bool
      @ole_obj.Closed
    end

    # ole obj Variant (array of doubles)
    # 3D WCS Control Points for the spline
    # @rbs return Array(Point3d)
    def control_points
    end

    # set the control points for the spline
    # @rbs pts Array(Point3d) | Array(Array[Double,Double,Double?])
    def control_points=(pts)
    end

    def degree
    end
  end
end
