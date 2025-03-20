module Autocad
  class Plot < Element
    # Configure which layouts to include in the plot
    # @rbs *layouts: Array<String | Autocad::Layout> | String | Autocad::Layout -- Layout names or objects
    # @rbs return void
    # @example Plot specific layouts
    #   plot.set_layouts_to_plot('Layout1', 'Layout2')
    #   plot.set_layouts_to_plot([drawing.paper_space_layout])
    # @note Converts Layout objects to their names automatically
    def set_layouts_to_plot(*layouts)
      layouts = layouts.first if layouts.size == 1 && layouts.first.is_a?(Array)
      ole_layouts = layouts.map { |l| l.is_a?(Autocad::Layout) ? l.name : l.to_s }
      
      ole_layout_values = WIN32OLE::Variant.new(
        ole_layouts,
        WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_BSTR
      )
      ole_obj.SetLayoutsToPlot(ole_layout_values)
    end

    # Display full plot preview window
    # @rbs return void
    # @note Uses AutoCAD's full preview mode (acFullPreview = 1)
    def plot_preview
      ole_obj.DisplayPlotPreview(1) # 1 = acFullPreview
    end

    # Execute plot using configured device
    # @rbs return void
    # @raise [Autocad::Error] If device communication fails
    # @example
    #   plot_to_device if plot_config.device_name == 'Default Printer'
    def plot_to_device
      ole_obj.PlotToDevice
    rescue => e
      raise Autocad::Error.new("Device plot failed: #{e.message}")
    end

    # Plot to file with specified configuration
    # @rbs filename: String | Pathname -- Output path for plot file
    # @rbs plot_config: String | Autocad::PlotConfiguration? -- Configuration name or object
    # @rbs return void
    # @example PDF output
    #   plot_to_file("output.pdf", plot_config: "High Quality PDF")
    # @example DWG to PDF
    #   plot_to_file(Pathname("drawing.pdf"), plot_config: drawing.pdf_plot_config)
    # @raise [Autocad::Error] If file creation fails
    def plot_to_file(filename, plot_config: nil)
      path = app.windows_path(filename)
      config_name = plot_config.respond_to?(:name) ? plot_config.name : plot_config
      ole_obj.PlotToFile(path, config_name)
    rescue => e
      raise Autocad::Error.new("File plot failed: #{e.message}\nPath: #{path}")
    end
  end
end
