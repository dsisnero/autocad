module Autocad
  class Point < Element
    def coordinates
      Point3d(ole_obj.Coordinates)
    end
  end
end
