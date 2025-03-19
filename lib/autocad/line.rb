# rbs_inline: enabled

require_relative 'element'

module Autocad
  class Line < Element
    # @rbs return float
    def length
      ole_obj.length
    end

    # @rbs return bool
    def line?
      true
    end

    # the start point of the line
    # @rbs return Point3d
    def start_point
      Point3d.new(ole_obj.StartPoint)
    end

    # the end point of the line
    # @rbs return Point3d
    def end_point
      Point3d.new(ole_obj.EndPoint)
    end

    # @rbs return Point3d
    def normal
      Point3d.new ole_obj.Normal
    end

    # the thickness of the line
    # @rbs return float
    def thickness
      ole_obj.Thickness
    end

    # the difference between the start and end point
    # @rbs return Point3d
    def delta
      Point3d.new ole_obj.Delta
    end
  end

  class Circle < Element
    # the center of the circle
    # @rbs return Point3d
    def center
      Point3d.new(ole_obj.Center)
    end

    # the radius of the circle
    # @rbs return Point3d
    def radius
      Point3d.new(ole_obj.Radius)
    end
  end

  class Polyline < Element
    # @rbs return Point3d
    def length
      Point3d.new @ole_obj.Length
    end

    # @rbs return Array[Point3d]
    def coordinates
      @ole_obj.coordinates.map { |pt| Point3d.new(pt) }
    end
  end
end
