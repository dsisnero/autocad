module Autocad
  class Layout < PlotConfiguration
    # Inserts a block into the layout
    # @rbs block: Block
    # @rbs pt: Point3d?
    # @rbs return void
    def insert_block(block, pt: nil)
    end

    # Get the layout name
    # @rbs return String
    def name
      @ole_obj.Name
    end

    # Set the layout name
    # @rbs str: String
    # @rbs return void
    def name=(str)
      @ole_obj.Name = str
    end

    # Copy plot settings from another configuration
    # @rbs pc: PlotConfiguration
    # @rbs return void
    def copy_plot_configuration(pc)
      ole_obj.CopyFrom(pc.ole_obj)
    end

    # Insert a block reference into the layout
    # @rbs name: String
    # @rbs pt: Point3d
    # @rbs rotation: Float
    # @rbs scale: Float
    # @rbs return BlockReference?
    # @raise [StandardError] On insertion failure
    def add_block_reference(name, pt:, rotation: 0.0, scale: 1.0)
      name = name.to_s
      name = app.windows_path(name) if File.file?(name)
      
      pt3d = Point3d.new(pt)
      ole_reference = ole_obj.Block.InsertBlock(pt3d.to_ole, name.to_s,
        scale.to_f, scale.to_f, scale.to_f, rotation.to_f)
      app.wrap(ole_reference)
    rescue StandardError => e
      app.error_proc.call(e, self)
      nil
    end

    # Get layout tab order position
    # @rbs return Integer
    def tab_order
      @ole_obj.TabOrder
    end

    # Set layout tab order position
    # @rbs n: Integer
    # @rbs return void
    def tab_order=(n)
      @ole_obj.TabOrder = n
    end

    # Get paper dimensions in millimeters
    # @rbs return [Float, Float]
    def paper_size
      width = WIN32OLE_VARIANT.new(nil, WIN32OLE::VARIANT::VT_BYREF | WIN32OLE::VARIANT::VT_R8)
      height = WIN32OLE_VARIANT.new(nil, WIN32OLE::VARIANT::VT_BYREF | WIN32OLE::VARIANT::VT_R8)
      @ole_obj.GetPaperSize(width, height)
      [width.value, height.value]
    end

    # Calculate usable area bounds with margins
    # @rbs return BoundingBox
    def bounds
      width, height = paper_size
      lower_left, upper_right = paper_margins
      lower_left_pt = lower_left
      upper_right_pt = Point3d(width, height) - upper_right
      BoundingBox.from_min_max(lower_left_pt, upper_right_pt)
    end

    # Get paper size in inches
    # @rbs return [Float, Float]
    def paper_size_inches
      width, height = paper_size
      [width / 25.4, height / 25.4]
    end

    # Add a paper space viewport
    # @rbs scale: Symbol
    # @rbs return PViewport
    def add_pviewport(scale = :scale_to_fit)
      psize_width, psize_h = paper_size
      margins = paper_margins
      width_mm = psize_width - margins[0][0] - margins[1][0]
      height_mm = psize_h - margins[0][1] - margins[1][1]
      width = width_mm / paper_units_scale_factor
      height = height_mm / paper_units_scale_factor

      center = [width / 2.0, height / 2.0]
      pv = drawing.paper_space.add_pv_viewport(center, width: width, height: height)
      pv.on
      pv.standard_scale = scale
      pv
    end

    # Get page margins
    # @rbs return [[Float, Float], [Float, Float]]
    def paper_margins
      lower_left = nil
      upper_right = nil
      @ole_obj.GetPaperMargins lower_left, upper_right
      lower_left, upper_right = WIN32OLE::ARGV
      [lower_left, upper_right]
    rescue StandardError => e
      puts "Error getting paper margins: #{e.message}"
      [[0.0, 0.0], [0.0, 0.0]]  # Return default values instead of breaking
    end
  end
end
