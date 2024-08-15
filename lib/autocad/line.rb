require_relative "element"

module Autocad
  class Line < Element
    def length
      ole_obj.length
    end

    def start_point
      Point3d(ole_obj.StartPoint)
    end

    def end_point
      Point3d(ole_obj.EndPoint)
    end
  end

  class Polyline < Element
    def length
      @ole_obj.Length
    end

    def coordinates
      @ole_obj.coordinates
    end
  end
end
