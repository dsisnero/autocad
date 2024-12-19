# rbs_inline: enabled

require_relative "element"

module Autocad
  class Line < Element
    def length
      ole_obj.length
    end

    def line?
      true
    end

    def start_point # : Point3d
      Point3d(ole_obj.StartPoint)
    end

    def end_point # : Point3d
      Point3d(ole_obj.EndPoint)
    end
  end

  class Circle < Element
    def center
      Point3d.new(ole_obj.Center)
    end

    def radius
      Point3d.new(ole_obj.Radius)
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
