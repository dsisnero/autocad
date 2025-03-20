module Autocad
  class Layout < PlotConfiguration
    def insert_block(block, pt: nil)
    end

    # The name of the layout
    # @rbs return String
    def name
      @ole_obj.Name
    end

    # @rbs name: String -- the name of the layout
    # @rbs return void
    def name=(str)
      @ole_obj.Name = str
    end

    # @rbs param pc: PlotConfiguration
    # @rbs return void
    def copy_plot_configuration(pc)
      ole_obj.CopyFrom(pc.ole_obj)
    end

    # @rbs name: String -- the name of the block to add
    # @rbs pt: Point3d -- the point to insert the block
    # @rbs rotation: Float -- the rotation of the block
    # @rbs scale: Float -- the scale of the block
    # @rbs return BlockReference
    def add_block_reference(name, pt:, rotation: 0.0, scale: 1.0)
      name = name.to_s
      name = app.windows_path(name) if File.file?(name)
      # new_scale = paper_units_scale_factor * scale

      pt3d = Point3d.new(pt)
      ole_reference = ole_obj.Block.InsertBlock(pt3d.to_ole, name.to_s,
        scale.to_f, scale.to_f, scale.to_f, rotation.to_f)
      app.wrap(ole_reference)
      # scale = bounds.scale_to_fit(blk.bounds)
      # blk.scale_by(scale)
    rescue StandardError
      nil
    end

    # @rbs return Integer -- the TabOrder of layout
    def tab_order
      @ole_obj.TabOrder
    end

    # set the TabOrder of a named layout
    # @rbs n: Integer
    # @rbs return void
    def tab_order=(n)
      @ole_obj.TabOrder = n
    end

    # in inches -note paper units is for display and doesnt affect the return
    # value of GetPaperSize returns mm paper size
    # @rbs return Array[Float, Float] -- return the width and height of the paper
    def paper_size
      width = WIN32OLE_VARIANT.new(nil, WIN32OLE::VARIANT::VT_BYREF | WIN32OLE::VARIANT::VT_R8)
      height = WIN32OLE_VARIANT.new(nil, WIN32OLE::VARIANT::VT_BYREF | WIN32OLE::VARIANT::VT_R8)
      @ole_obj.GetPaperSize(width, height)
      [width.value, height.value]
    end

    # make a Autocad::BoundingBox from the usable_area
    def bounds
      width, height = paper_size
      lower_left, upper_right = paper_margins
      # Point3d(0,0) + lower_left = lower_left
      lower_left_pt = lower_left
      upper_right_pt = Point3d(width, height) - upper_right
      BoundingBox.from_min_max(lower_left_pt, upper_right_pt)
    end

    def paper_size_inches
      width, height = paper_size
      [width / 25.4, height / 25.4]
    end

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

    def paper_margins
      lower_left = nil
      upper_right = nil
      @ole_obj.GetPaperMargins lower_left, upper_right
      lower_left, upper_right = WIN32OLE::ARGV
      [lower_left, upper_right]
    rescue StandardError => e
      puts "Error getting paper margins: #{e.message}"
      [[0, 0], [0, 0]]  # Return default values instead of breaking
    end
  end
end
