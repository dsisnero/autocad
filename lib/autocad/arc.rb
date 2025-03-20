require_relative "element"

module Autocad
  class Arc < Element
    # @rbs return Float
    def length
      @ole_obj.ArcLength
    end

    # @rbs return Point3d
    def start_point
      Point3d(ole_obj.StartPoint)
    end

    # @rbs return Point3d
    def end_point
      Point3d(ole_obj.EndPoint)
    end

    def start_angle
      @ole_obj.StartAngle
    end

    def end_angle
      @ole_obj.EndAngle
    end

    def total_angle
      @ole_obj.TotalAngle
    end
  end
end
