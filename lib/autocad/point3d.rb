module Autocad
  class Point3d
    class << self
      def cartesian_to_polar(x, y)
        r = Math.sqrt(x * x + y * y)
        angle = Angle.radians(Math.atan2(y, x))
        [r, angle]
      end

      def from_polar_degrees(r, a)
      end

      def from_ole(ole)
        new(ole.X, ole.Y, ole.Z)
      end

      def polar_to_cartesian(r, a)
      end
    end

    attr_reader :x, :y, :z

    def initialize(_x = nil, _y = nil, _z = nil, x: _x, y: _y, z: _z)
      case [x, y, z]
      in [Array, nil, nil]
        @x = x[0].to_f
        @y = x[1].to_f
        @z = x[2].to_f
      in [Float, Float, Float]
        @x = x
        @y = y
        @z = z
      else
        @x = x.to_f || 0.0
        @y = y.to_f || 0.0
        @z = z.to_f || 0.0
      end
    end

    def +(other)
      case other
      when Point3d
        self.class.new(x + other.x, y + other.y, z + other.z)
      when Array
        self.class.new(x + other[0], y + other[1])
      end
    end

    def deconstruct
      [@x, @y, @z]
    end

    def deconstruct_keys
      {x: @x, y: @y, z: @z}
    end

    def to_ary
      [x, y, z]
    end

    def -(other)
      case other
      when Point3d
        self.class.new(x - other.x, y - other.y, z - other.z)
      when Array
        self.class.new(x - other[0], y - other[1])
      end
    end

    def to_s
      "Point3d(#{x}, #{y}, #{z})"
    end

    def to_a
      [x, y, z]
    end

    def zero
      new(0.0, 0.0, 0, 0)
    end

    def to_cartesian
    end
  end
end
