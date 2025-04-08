module Autocad
  class PlotConfiguration < Element
    # Get the name of the plot configuration
    # @rbs return String
    def name
      @ole_obj.Name
    end

    # Set the plot device configuration file
    # @rbs name: String
    # @rbs return void
    def device_name=(name)
      @ole_obj.ConfigName = name
    end

    # Get the current plot device configuration name
    # @rbs return String
    def device_name
      @ole_obj.ConfigName
    end

    # Read current configuration properties from OLE object
    # @rbs return Hash[Symbol, Object]
    def read_ole(ole = nil)
      {device_name: ole_obj.ConfigName,
       media_name: ole_obj.CanonicalMediaName,
       style_sheet: ole_obj.StyleSheet,
       plot_type: plot_type_ole_to_sym(ole_obj.PlotType),
       rotation: rotation_ole_to_degree(ole_obj.PlotRotation),
       paper_units: paper_units_from_ole(ole_obj.PaperUnits)}
    end

    # Write configuration settings to OLE object
    # @rbs value: Hash[Symbol, Object]
    # @rbs return void
    def write_ole(value)
      ole_obj.ConfigName = value[:device_name] if value[:device_name]
      ole_obj.CanonicalMediaName = value[:media_name] if value[:media_name]
      ole_obj.StyleSheet = value[:style_sheet] if value[:style_sheet]
      ole_obj.PlotType = plot_type_to_ole(value[:plot_type]) if value[:plot_type]
      ole_obj.PlotRotation = rotation_degree_to_ole(value[:rotation]) if value[:rotation]
      ole_obj.PaperUnits = paper_units_to_ole(value[:paper_units]) if value[:paper_units]
    end

    # Get plot origin point in millimeters
    # @rbs return Point3d
    def plot_origin
      Point3d.new(ole_obj.PlotOrigin)
    end

    # Set plot origin point
    # @rbs ...: Numeric | Array[Numeric] | Point3d
    # @rbs return void
    # @raise [ArgumentError] For invalid coordinate values
    def plot_origin=(...)
      origin = Point3d.new(...)
      ole_obj.PlotOrigin = origin.to_ole
    rescue => e
      app.error_proc.call(e, self)
    end

    # Get current plot style mode
    # @rbs return Symbol
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

    # Check if using color-dependent plot styles
    # @rbs return bool
    def color_style_mode?
      plot_style_mode == :color_style_mode
    end

    # Check if using named plot styles
    # @rbs return bool
    def named_style_mode?
      plot_style_mode == :named_style_mode
    end

    # Configure multiple plot settings at once
    # @rbs kwargs: Hash{Symbol => Object} -- See write_ole for valid keys
    # @rbs return void
    # @example Configure for PDF output
    #   setup(
    #     device_name: "AutoCAD PDF.pc3",
    #     media_name: "ANSI_D",
    #     style_sheet: "monochrome.ctb",
    #     plot_type: :layout
    #   )
    def setup(...)
      write_ole(...)
    end

    # Update configuration with merged values
    # @rbs value: Hash{Symbol => Object} -- Partial configuration updates
    # @rbs return void
    def update(value)
      merged_value = original.merge(value)
      super(merged_value)
    rescue => e
      binding.irb
    end

    # Print current configuration to console
    # @rbs return void
    def display_setup
      original.each { |k, v| puts "#{k}: #{v}" }
      puts "plot_style_mode: #{plot_style_mode}"
    end

    # Copy settings from another configuration
    # @rbs pc: PlotConfiguration -- Source configuration
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

    # ANSI B landscape paper size name
    # @rbs return String -- Canonical name "ANSI_B_(17.00_x_11.00_Inches)"
    def ansi_b_landscape
      'ANSI_B_(17.00_x_11.00_Inches)'
    end

    def ansi_d_landscape
      'ANSI_D_(34.00_x_22.00_Inches)'
    end

    def ansi_d_landscape_full_bleed
      'ANSI_full_bleed_D_(34.00_x_22.00_Inches)'
    end

    # Refresh plot device information
    # @rbs return void
    # @note Required after changing device configurations
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
    # @note Call refresh() first if device was changed
    def media_names
      refresh
      @ole_obj.GetCanonicalMediaNames
    end

    def locale_media_name
      @ole_obj.GetLocaleMediaName(canonical_media_name)
    end

    # Returns the different plot tables. Use one of these
    # when setting style_sheet
    # @rbs return Array[String] -- CTB/STB file names
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

    # Get current paper units
    # @rbs return Symbol -- :inches, :mm, or :pixels
    def paper_units
      paper_units_from_ole(@ole_obj.PaperUnits)
    end

    # Conversion factor to millimeters based on paper units
    # @rbs return Float
    # @example
    #   inches: 25.4 (mm per inch)
    #   pixels: 25.4/96 (mm per pixel at 96 DPI)
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

    # Convert paper units symbol to OLE constant
    # @rbs unit: Symbol -- Valid values: :inches, :mm, :pixels
    # @rbs return Integer -- OLE constant (ACAD::Ac*)
    # @raise [ArgumentError] For invalid paper units
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

    # Convert OLE paper units constant to symbol
    # @rbs unit: Integer -- OLE constant (ACAD::Ac*)
    # @rbs return Symbol -- :inches, :mm, or :pixels
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

    # Convert rotation degrees to OLE constant
    # @rbs degree: Integer -- Valid values: 0, 90, 180, 270
    # @rbs return Integer -- OLE constant (ACAD::Ac*degrees)
    # @raise [ArgumentError] For invalid rotation values
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

    # Convert OLE rotation constant to degrees
    # @rbs rot: Integer -- OLE constant (ACAD::Ac*degrees)
    # @rbs return Integer -- 0, 90, 180, or 270
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

    # Convert OLE plot type constant to symbol
    # @rbs typ: Integer -- OLE constant (ACAD::Ac*)
    # @rbs return Symbol -- :display, :extents, :layout, :limits, :view, or :window
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

    # Convert plot type symbol to OLE constant
    # @rbs typ: Symbol -- Valid values:
    #   :display, :extents, :layout, :limits, :view, :window
    # @rbs return Integer -- OLE constant (ACAD::Ac*)
    # @raise [ArgumentError] For invalid plot types
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
