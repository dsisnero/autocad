module Autocad
  class Viewport < Element
    # Returns the name of the viewport
    # @rbs return String
    def name
      ole_obj.Name
    end

    # Returns the center of the viewport
    # @rbs return Point3d
    def center
      Point3d.new(ole_obj.Center)
    end

    # Returns the width of the viewport
    # @rbs return Float
    def width
      ole_obj.Width
    end

    # Splits the viewport
    #  the split_type is from the AcViewportSplitType enum
    #  can take the integer or symbol corressponding to the enum
    def split(split_type)
      case split_type
      when Integer then ole_obj.Split(split_type)
      when :horizontal then ole_obj.Split(0)
      when :vertical then ole_obj.Split(1)
      when :two_horizontal then ole.Split(0)
      when :two_vertical then ole_obj.Split(1)
      when :three_left then ole_obj.Split(2)
      when :three_right then ole_obj.Split(3)
      when :three_horizontal then ole_obj.Split(4)
      when :three_vertical then ole_obj.Split(5)
      when :three_above then ole_obj.Split(6)
      when :three_below then ole_obj.Split(7)
      when :four then ole_obj.Split(8)
      end
    end

    def height
      ole_obj.Height
    end

    def lower_left
      ole_obj.LowerLeftCorner.map { |p| Point3d.new(p) }
    end

    alias_method :bottom_left, :lower_left

    def upper_right
      ole_obj.UpperRightCorner.map { |p| Point3d.new(p) }
    end

    alias_method :top_right, :upper_right
  end
end
