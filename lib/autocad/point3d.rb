# rbs_inline: enabled

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

      # convert array of points to array of x,y coordinates
      # array can be [ Point3d, Point3d, ..]
      # array can be [  [x,y,z], [x,y,z], [x,y,z] ..]
      # array can be [x,y, x1, y1, x2,y2, x3,y3]
      # array can be [[x,y], [x2,y2], [x3,y3]]
      # all coordinates are converted to float
      # z coordinates are ignored
      # @rbs return Array[Float]
      def pts_to_array(pts)
        case pts.first
        when Point3d
          pts.flat_map(&:to_xy)
        when Array
          pts.flat_map { |pt| [pt[0].to_f, pt[1].to_f] }
        when Numeric
          pts.each_slice(2).flat_map { |x, y| [x.to_f, y.to_f] }
        end
      end

      def array_to_ole(ar)
        WIN32OLE::Variant.new(ar, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)
      end
    end

    attr_reader :x, :y, :z

    def initialize(_x = nil, _y = nil, _z = nil, x: _x, y: _y, z: _z)
      case [x, y, z]
      in [Point3d, y, z]
        @x = x.x
        @y = x.y
        @z = x.z
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

    # @rbs other: Point3d | [Float,Float,Float]
    def +(other) # : Point3d
      case other
      when Point3d
        self.class.new(x + other.x, y + other.y, z + other.z)
      when Array
        self.class.new(x + other[0], y + other[1])
      end
    end

    def distance_to(other)
      pt2 = Point3d.new(other)
      Math.sqrt((x - pt2.x)**2 + (y - pt2.y)**2 + (z - pt2.z)**2)
    end

    # @rbs return [Float,Float, Float]
    def deconstruct
      [@x, @y, @z]
    end

    # @rbs return { x: Float, y: Float, z: Float}
    def deconstruct_keys
      { x: @x, y: @y, z: @z }
    end

    # @rbs return [Float,Float, Float]
    def to_ary
      [x, y, z]
    end

    # @rbs other: Point3d | [Float,Float,Float]
    def -(other) # : Point3d
      case other
      when Point3d
        self.class.new(x - other.x, y - other.y, z - other.z)
      when Array
        self.class.new(x - other[0], y - other[1])
      end
    end

    def to_xy
      [x, y]
    end

    def xy_bounds(other)
      x2, y2 = Points3d.new(other).to_xy
      [x, y, x2, y, x2, y2, x, y2, x, y]
    end

    def to_s
      "Point3d(#{x}, #{y}, #{z})"
    end

    # @rbs return [Float,Float, Float]
    def to_a
      [x, y, z]
    end

    # @rbs return Point3d -- return a Point3d at [0,0,0]
    def zero
      new(0.0, 0.0, 0, 0)
    end

    def to_cartesian
    end

    def to_ole
      ole = WIN32OLE::Variant.array([3], WIN32OLE::VARIANT::VT_R8)
      ole[0] = x
      ole[1] = y
      ole[z] = z
      ole
    end
  end
end
