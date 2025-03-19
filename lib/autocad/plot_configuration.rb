module Autocad
  class PlotConfiguration < Element
    # the name of the plot configuration
    # @rbs return String
    def name
      @ole_obj.Name
    end

    # assign a plot device file to the plot config
    # @rbs name: String
    # @rbs return void
    def device_name=(name)
      @ole_obj.ConfigName = name
    end

    def device_name
      @ole_obj.ConfigName
    end

    def read_ole(ole)
      {device_name: ole_obj.ConfigName,
       media_name: ole_obj.CanonicalMediaName,
       style_sheet: ole_obj.StyleSheet,
       plot_type: plot_type_ole_to_sym(ole_obj.PlotType),
       rotation: rotation_ole_to_degree(ole_obj.PlotRotation),
       paper_units: paper_units_from_ole(ole_obj.PaperUnits)}
    end

    def write_ole(value)
      ole_obj.ConfigName = value[:device_name]
      ole_obj.CanonicalMediaName = value[:media_name]
      ole_obj.StyleSheet = value[:style_sheet]
      ole_obj.PlotType = plot_type_to_ole(value[:plot_type])
      ole_obj.PlotRotation = rotation_degree_to_ole(value[:rotation])
      ole_obj.PaperUnits = paper_units_to_ole(value[:paper_units])
    end

    # @rbs return Point3d -- the plot origin in wcs coordinates - always mm unit returned
    def plot_origin
      Point3d.new(ole_obj.PlotOrigin)
    end

    # @rbs -- accepts the same parameters as Point3d.new
    def plot_origin=(...)
      origin = Point3d.new(...)
      ole_obj.PlotOrigin = origin.to_ole
    rescue StandardError => e
      app.error_proc.call(e, self)
    end

    def plot_style_mode
      style = drawing.get_variable('pstylemode')
      case style
      when 0
        :named_style_mode
      else
        :color_style_mode
      end
    end

    def plot_style_mode_variable
      drawing.get_variable('pstylemode')
    end

    def color_style_mode?
      plot_style_mode == :color_style_mode
    end

    def named_style_mode?
      plot_style_mode == :named_style_mode
    end

    # setup(device_name: "FAA.pc3", media_name: "ANSI_D_(36.00)",
    #      style: "acad.ctb", plot_type: :extents, rotation: 0  )
    def setup(...)
      write_ole(...)
    end

    def update(value)
      merged_value = original.merge(value)
      super(merged_value)
    rescue StandardError => e
      binding.irb
    end

    # shows the current plot configuration settings
    def display_setup
      original.each { |k, v| puts "#{k}: #{v}" }
      puts "plot_style_mode: #{plot_style_mode}"
    end

    # @rbs param pc: PlotConfiguration
    # @rbs return void
    def copy_plot_configuration(pc)
      ole_obj.CopyFrom(pc.ole_obj)
    end

    def plot_style_mode=(sym)
      style = case sym
      when :named, :named_style, :named_style_mode
        0
      when :color, :color_style, :color_style_mode
        1
      else
        raise 'need either :named or :color'
      end
      drawing.set_variable('pstylemode', style)
    end

    def ansi_b_landscape
      'ANSI_B_(17.00_x_11.00_Inches)'
    end

    def ansi_d_landscape
      'ANSI_D_(34.00_x_22.00_Inches)'
    end

    def refresh
      @ole_obj.RefreshPlotDeviceInfo
    end

    def style_sheet=(style)
      ole_obj.StyleSheet = style
    end

    def style_sheet
      ole_obj.StyleSheet
    end

    # The media devices available to for plotting
    # @rbs return Array[String]
    def device_names
      refresh
      @ole_obj.GetPlotDeviceNames
    end

    # The current device_name for printing as its Canonomical Name
    # use this name when changing
    # @rbs return String
    def canonical_media_name
      @ole_obj.CanonicalMediaName
    end

    def canonomical_media_name=(name)
      @ole_obj.CanonicalMediaName = name
    end

    # The available paper sizes for the configured device. Use this
    # when setting the media_name:
    # @rbs return Array[String]
    def media_names
      refresh
      @ole_obj.GetCanonicalMediaNames
    end

    def locale_media_name
      @ole_obj.GetLocaleMediaName(canonical_media_name)
    end

    # Returns the different plot tables. Use one of these
    # when setting style_sheet
    # @rbs return Array[String]
    def plot_style_table_names
      refresh
      @ole_obj.GetPlotStyleTableNames
    end

    # The different plot bounds or types
    # @rbs return Array[Symbol]
    def plot_types
      %i[display extents layout limits view window]
    end

    # @rbs return Array[Float, Float] -- the numerator and denominator for a custom scale
    def custom_scale
      numerator = WIN32OLE_VARIANT.new(nil, WIN32OLE::VARIANT::VT_BYREF | WIN32OLE::VARIANT::VT_R8)
      denominator = WIN32OLE_VARIANT.new(nil, WIN32OLE::VARIANT::VT_BYREF | WIN32OLE::VARIANT::VT_R8)
      @ole_obj.GetCustomScale(numerator, denominator)
      [numerator.value, denominator.value]
    end

    # The different paper units
    # @rbs return Array[Symbol]
    def paper_units_types
      %i[inches mm pixels]
    end

    def paper_units
      paper_units_from_ole(@ole_obj.PaperUnits)
    end

    def paper_units_scale_factor
      unit = paper_units
      case unit

      when :inches
        25.4

      when :mm
        1

      # pixel to mm
      when :pixels
        25.4 / 96.0
      end
    end

    private

    def paper_units_to_ole(unit)
      case unit

      when :inches

        ACAD::AcInches

      when :pixels

        ACAD::AcPixels

      when :mm

        ACAD::AcMillimeters

      end
    end

    def paper_units_from_ole(unit)
      case unit

      when ACAD::AcInches

        :inches

      when ACAD::AcPixels

        :pixels

      when ACAD::AcMillimeters

        :mm

      end
    end

    def rotation_degree_to_ole(degree)
      case degree
      when 0
        ACAD::Ac0degrees
      when 90
        ACAD::Ac90degrees
      when 180
        ACAD::Ac180degrees
      when 270
        ACAD::Ac270degrees
      end
    end

    def rotation_ole_to_degree(rot)
      case rot

      when ACAD::Ac0degrees
        0
      when ACAD::Ac90degrees
        90
      when ACAD::Ac180degrees
        180
      when ACAD::Ac270degrees
        270
      end
    end

    def plot_type_ole_to_sym(typ)
      case typ
      when ACAD::AcDisplay
        :display
      when ACAD::AcExtents
        :extents
      when ACAD::AcLayout
        :layout
      when ACAD::AcLimits
        :limits
      when ACAD::AcView
        :view
      when ACAD::AcWindow
        :window
      end
    end

    def plot_type_to_ole(typ)
      case typ
      when :display
        ACAD::AcDisplay
      when :extents
        ACAD::AcExtents
      when :layout
        ACAD::AcLayout
      when :limits
        ACAD::AcLimits
      when :view
        ACAD::AcView
      when :window
        ACAD::AcWindow
      end
    end
  end
end
