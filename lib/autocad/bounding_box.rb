module Autocad
  # A BoundingBox represents a bounding box around a picture.
  #
  # A bounding box also defines a local coordinate system for a picture. The
  # bounding box must contain the origin of the coordinate system. However the
  # origin need not be centered within the box.
  #
  # No particular guarantees are made about the tightness of the bounding box,
  # though it can assumed to be reasonably tight.
  class BoundingBox
    class << self
      def empty
        new(0, 0, 0, 0)
      end

      # Create a BoundingBox with the given width and height and
      # the origin centered within the box.
      def centered(width, height)
        w = width / 2.0
        h = height / 2.0
        new(-w, h, w, -h)
      end

      # Create a BoundingBox from minimum and maximum points
      def from_min_max(min_pt, max_pt)
        min_pt = Point3d.new(min_pt)
        max_pt = Point3d.new(max_pt)

        new(
          min_pt.x,  # left
          max_pt.y,  # top
          max_pt.x,  # right
          min_pt.y   # bottom
        )
      end
    end

    attr_reader :left, :top, :right, :bottom

    def initialize(left, top, right, bottom)
      @left = left
      @top = top
      @right = right
      @bottom = bottom
    end

    def hash
      [self.class, left, top, right, bottom].hash
    end

    def eql?(other)
      other.class == self.class &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom
    end

    def ==(other)
      return false unless other.is_a?(BoundingBox)

      left.round(6) == other.left.round(6) &&
        top.round(6) == other.top.round(6) &&
        right.round(6) == other.right.round(6) &&
        bottom.round(6) == other.bottom.round(6)
    end

    def upper_right
      Point3d.new(right, top, 0)
    end

    alias_method :top_right, :upper_right

    def lower_left
      Point3d.new(left, bottom, 0)
    end

    alias_method :bottom_left, :lower_left

    def center
      Point3d.new((left + right) / 2.0, (top + bottom) / 2.0, 0)
    end

    def contains?(pt)
      pt.x >= left && pt.x <= right && pt.y >= bottom && pt.y <= top
    end

    def width
      right - left
    end

    def height
      top - bottom
    end

    def on(other)
      self.class.new(
        [left, other.left].min,
        [top, other.top].max,
        [right, other.right].max,
        [bottom, other.bottom].min
      )
    end

    def beside(other)
      self.class.new(
        -(width + other.width) / 2.0,
        [top, other.top].max,
        (width + other.width) / 2.0,
        [bottom, other.bottom].min
      )
    end

    def above(other)
      self.class.new(
        [left, other.left].min,
        (height + other.height) / 2.0,
        [right, other.right].max,
        -(height + other.height) / 2.0
      )
    end

    # Evaluate the landmark relative to the origin of this bounding box,
    # returning the location described by the landmark.
    def eval(landmark)
      Point3d.new(
        landmark.x.eval(left, right),
        landmark.y.eval(bottom, top),
        0
      )
    end

    def at(point)
      x = point.x
      y = point.y

      new_left = [left + x, 0].min
      new_top = [top + y, 0].max
      new_right = [right + x, 0].max
      new_bottom = [bottom + y, 0].min

      self.class.new(new_left, new_top, new_right, new_bottom)
    end

    def at_landmark(landmark)
      at(eval(landmark))
    end

    def origin_at(point)
      # Vector maths to work out where the edges of the bounding box lie in
      # relation to the new origin
      new_top_left = Point3d.new(left, top, 0) - point
      new_bottom_right = Point3d.new(right, bottom, 0) - point

      # Make sure the bounding box includes the origin
      new_left = [new_top_left.x, 0].min
      new_top = [new_top_left.y, 0].max
      new_right = [new_bottom_right.x, 0].max
      new_bottom = [new_bottom_right.y, 0].min

      self.class.new(new_left, new_top, new_right, new_bottom)
    end

    def origin_at_landmark(landmark)
      origin_at(eval(landmark))
    end

    # Expand bounding box to enclose the given Point
    def enclose(point)
      self.class.new(
        [left, point.x].min,
        [top, point.y].max,
        [right, point.x].max,
        [bottom, point.y].min
      )
    end

    def scale_to_fit(bb)
      return 1 if bb.width == 0 || bb.height == 0

      [width / bb.width, height / bb.height].min
    end

    # Add expansion to all sides of this bounding box
    def expand(expansion)
      self.class.new(
        left - expansion,
        top + expansion,
        right + expansion,
        bottom - expansion
      )
    end

    def transform(transform)
      self.class.empty
        .enclose(transform.call(Point3d.new(left, top, 0)))
        .enclose(transform.call(Point3d.new(right, top, 0)))
        .enclose(transform.call(Point3d.new(left, bottom, 0)))
        .enclose(transform.call(Point3d.new(right, bottom, 0)))
    end
  end
end
