module Autocad
  class Plot < Element
    def set_layouts_to_plot(*layouts)
      # Convert argument array to flat array if first arg is array
      layouts = layouts.first if layouts.size == 1 && layouts.first.is_a?(Array)

      # Convert each item to layout name string
      ole_layouts = layouts.map do |layout|
        layout.is_a?(Autocad::Layout) ? layout.name : layout.to_s
      end

      ole_layout_values = WIN32OLE::Variant.new(ole_layouts,
        WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_BSTR)
      ole_obj.SetLayoutsToPlot(ole_layout_values)
    end

    def plot_to_file(filename, plot_config: nil)
      path = app.windows_path(filename)
      ole_obj.PlotToFile(path, plot_config)
    end
  end
end
