require_relative 'element'

module Autocad
  class PViewport < Element
    # the viewport width
    # @rbs return Float
    def width
      @ole_obj.Width
    end

    def width_inches
      width / 25.4
    end

    def height_inches
      height / 25.4
    end

    def pviewport?
      true
    end

    # change the viewport to front_view direction
    def front_view
      view_direction = Point3d(0, -1, 0)
      ole_obj.Direction = view_direction.to_ole
    end

    def top_view
      view_direction = Point3d(0, 0, 1)
      ole_obj.Direction = view_direction.to_ole
    end

    def right_view
      view_direction = Point3d(1, 0, 0)
      ole_obj.Direction = view_direction.to_ole
    end

    def isometric_view
      view_direction = Point3d(1, 1, 1)
      ole_obj.Direction = view_direction.to_ole
    end

    # the viewport height
    # @rbs return Float
    def height
      @ole_obj.Height
    end

    # @rbs return bool
    def on?
      @ole_obj.ViewPortOn
    end

    # turn on the view
    # @rbs return void
    def on
      @ole_obj.Display(true)
    end

    # turn of the display of viewport
    # @rbs return void
    def off
      @ole_obj.Display(false)
    end

    # the standard scale from Autocad AcViewportScale enum converted to symbol
    # @rbs return Symbol
    def standard_scale
      ole = @ole_obj.StandardScale
      standard_scale_ole_to_symbol(ole)
    end

    def standard_scale=(scale)
      if scale.is_a?(Symbol)
        ole = standard_scale_symbol_to_ole(scale)
        @ole_obj.StandardScale = ole
      else
        @ole_obj.StandardScale = scale
      end
    end

    def standard_scale_ole_to_symbol(scale)
      case scale
      when ACAD::AcVpScaleToFit then :scale_to_fit
      when ACAD::AcVpCustomScale then :custom
      when ACAD::AcVp1_128in_1ft then :"128_to_1"
      when ACAD::AcVp1_64in_1ft then :"64_to_1"
      when ACAD::AcVp1_32in_1ft then :"32_to_1"
      when ACAD::AcVp1_16in_1ft then :"16_to_1"
      when ACAD::AcVp1_8in_1ft then :"8_to_1"
      end
    end

    def standard_scale_symbol_to_ole(scale)
      case scale
      when :scale_to_fit then ACAD::AcVpScaleToFit
      when :custom then ACAD::AcVpCustomScale
      when :"128_to_1" then ACAD::AcVp1_128in_1ft
      when :"64_to_1" then ACAD::AcVp1_64in_1ft
      when :"32_to_1" then ACAD::AcVp1_32in_1ft
      when :"16_to_1" then ACAD::AcVp1_16in_1ft
      when :"8_to_1" then ACAD::AcVp1_8in_1ft
      end
    end

    # set a custom scale for model objects
    # @rbs scale: Float
    def custom_scale=(scale)
      @ole_obj.CustomScale = scale
    end

    def lock_display
      @ole_obj.DisplayLocked = true
    end

    # specifies the lock stat fo the viewports display. When locked, cant
    # change view
    # @rbs return bool
    def display_locked?
      @ole_obj.DisplayLocked
    end

    def unlock_display
      @ole_obj.DisplayLocked = false
    end

    def each
      return enum_for(:each) unless block_given?

      @ole_obj.each do |ole|
        yield app.wrap(ole)
      end
    end
  end
end
