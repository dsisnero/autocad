require_relative "element"

module Autocad
  class Arc < Element
    def length
      @ole_obj.ArcLength
    end

    def start_point
      Point3d(ole_obj.StartPoint)
    end

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
