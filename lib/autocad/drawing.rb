# rbs_inline: enabled

require_relative "event_handler"
require_relative "enumerator"
require_relative "model"
require_relative "selection_set_adapter"
require "debug"

module Autocad
  class Drawing
    include Common
    attr_reader :app

    def self.from_ole_obj(app, ole) #: Drawing
      new(app, ole)
    end

    def initialize(app, ole)
      @app = app
      @ole_obj = ole
      @app_event = WIN32OLE_EVENT.new(ole)
    end

    def event_handler #: EventHandler
      @event_handler ||= default_event_handler
    end

    def default_event_handler
      handler = EventHandler.new
      @app_event.handler = handler
      handler
    end

    def app_ole
      app.ole_obj
    end

    # @rbs return SelectionSetAdapter
    def create_selection_set(name)
      ss = SelectionSet.new(name)
      yield ss if block_given?
      SelectionSetAdapter.new(self, ss)
    end

    # register an handler
    #
    # @rbs event: String -- event key for handler
    # @rbs &: {() -> void} - handler Proc
    def register_handler(event, &) #:void
      @event_handler.add_handler(event, &) unless event == "OnQuit"
    end

    # @rbs return bool -- true if drawing is read only
    def read_only?
      ole_obj.ReadOnly
    end

    # @rbs return bool -- true if drawing is previously saved
    def previously_saved?
      ole_obj.FullName != ""
    end

    # @rbs return bool -- true if drawing is modified
    def modified?
      ole_obj.Saved == false
    end

    def save(name: nil, dir: nil) #: void
      return if read_only?
      if previously_saved? && modified?
        ole_obj.Save
      else
        out_name = dwg_path(name: name, dir: dir)
        windows_name = app.windows_path(out_name)
        ole_obj.SaveAs(windows_name)
      end
      puts "saved #{windows_name}"
    end

    def dwg_path(name: nil, dir: nil)
      name ||= self.name
      dir = Pathname.new(dir || dirname).expand_path
      dir.mkpath unless dir.directory?
      dir + dwg_name(name)
    end

    def dwg_name(name)
      Pathname.new(name).sub_ext(".dwg")
    end

    # save the drawing as a pdf file
    # if the name or directory is given it uses
    # those params. If not it uses the drawing name
    # and the drawing directory
    # @rbs name: String? - the name of the file
    # @rbs dir: String? - the directory to save the drawing
    def save_as_pdf(name: nil, dir: nil, model: false) #: void
      out_name = pdf_path(name: name, dir: dir)
      print_pdf(out_name, model:)
      puts "saved #{out_name}"
    end

    def pdf_path(name: nil, dir: nil)
      name ||= self.name
      dir = Pathname.new(dir || dirname).expand_path
      dir.mkpath unless dir.directory?
      dir + pdf_name(name)
    end

    def get_current_view_size
      h = get_variable("VIEWSIZE")
      screen_size = Point3d(get_variable("SCREENSIZE"))
      w = h * screen_size.x / screen_size.y
      [w, h]
    end

    # Todo
    # @rbs return Point3d -- the center of the view in world coordinates
    def view_center
      center = get_variable("VIEWCTR")
      Point3d(center)
    end

    # @rbs name: String
    # @rbs return PlotConfiguration
    def add_plot_configuration(name, model: false)
      plot_config = plot_configurations.find { |p| p.name == name }
      return plot_config if plot_config
      ole = @ole_obj.PlotConfigurations.Add(name, model)
      app.wrap(ole)
    rescue => ex
      app.error_proc.call(ex, self)
    end

    # returns the defined plot configuration "faa_ansid_bw".
    def pdf_plot_config #: PlotConfiguration
      @pdf_plot_config ||= create_pdf_plot_configutation
    end

    def default_plot_setup
      {device_name: "AutoCAD PDF (High Quality Print).pc3",
       media_name: "ANSI_D_(34.00_x_22.00_Inches)",
       style_sheet: "FAA_Black&Gray.ctb",
       plot_type: :layout,
       rotation: 0,
       paper_units: :inches}
    end

    # creates the "faa_ansid_bw" plot configuration
    def create_pdf_plot_configutation #: PlotConfiguration
      pc = add_plot_configuration("faa_ansid_bw")
      pc.update(default_plot_setup)
      pc
    end

    # Return the pdf name for the drawing.
    #
    # If a name is provided use the name provided otherwise use the drawing name
    #
    # @rbs name: String | nil -- change ext to pdf and return Pathname from
    # the name or drawing name
    def pdf_name(name = nil) #: Pathname
      name ||= self.name
      Pathname.new(name).sub_ext(".pdf")
    end

    def plot #: Plot
      ole = ole_obj.Plot
      ole.QuietErrorMode = true
      app.wrap(ole_obj.Plot)
    end

    def print_pdf(print_path, model: false)
      if model
        "puts print model"
      else
        print_paper_space_pdf(print_path)
      end
    end

    # @rbs return Layout -- The first layout that is not "Model"
    def paper_space_layout
      layouts.reject { it.name == "Model" }.first
    end

    def print_paper_space_pdf(print_path)
      plotter = plot
      plotter.set_layouts_to_plot paper_space_layout
      if print_path.file?
        print_path.delete if print_path.file?
      end
      plotter.plot_to_file(print_path)
    end

    # copy the drawing
    # @rbs name: String | Pathname --name of the file
    # @rbs dir: String|Pathname -- dir
    def copy(name: nil, dir: nil) #: void
      if dir.nil?
        lname = name || copy_name
        dir_path = dirname
      else
        lname = name || self.name
        dir_path = Pathname.new(dir)
      end
      copy_path = dir_path + lname
      FileUtils.copy path.to_s, copy_path.to_s, verbose: true
    end

    # If you copy the file the name to use
    # @rbs backup_str: String -- the bqckup string to use for copies
    def copy_name(backup_str = ".copy")
      lname = name.dup
      ext = File.extname(lname)
      "#{File.basename(lname, ext)}#{backup_str}#{ext}"
    end

    def paper_space? #: bool
      ole_obj.ActiveSpace == ACAD::AcPaperSpace
    end

    def model_space? #: bool
      ole_obj.ActiveSpace == ACAD::AcModelSpace
    end

    def to_paper_space #: void
      ole_obj.ActiveSpace = ACAD::AcPaperSpace
    end

    def to_model_space #: void
      ole_obj.ActiveSpace = ACAD::AcModelSpace
    end

    # @rbs return String -- the name of the drawing
    def name
      ole_obj.Name
    end

    # @rbs return Pathname -- the name as Pathname
    def basename
      Pathname.new(name)
    end

    # @rbs return Pathname -- the directory of the file
    def dirname
      Pathname.new(ole_obj.Path).expand_path
    end

    # @rbs return Pathname -- the complete path of file
    def path
      dirname + basename
    end

    # @rbs return Layer -- the active layer
    def active_layer
      ole = ole_obj.ActiveLayer
      app.wrap(ole)
    end

    # @rbs return String -- the name of the active layer
    def active_layer_name
      ole_obj.ActiveLayer.Name
    end

    # @rbs layer: Layer | String -- make the given layer active
    def active_layer=(layer)
      if layer.is_a?(String)
        layer = ole_obj.Layers.Item(layer)
      elsif layer.is_a?(Autocad::Layer)
        layer = layer.to_ole
      end
      raise "layer not found" unless layer
      ole_obj.ActiveLayer = layer.to_ole
    end

    # @rbs vport: Autocad::PViewport -- viewport to make active
    # @rbs return void
    def active_pviewport=(vport)
      ole_obj.ActivePViewport = vport.to_ole
    end

    # return the active PViewport
    # @rbs return PViewport
    def active_pviewport
      ole = ole_obj.ActivePViewport
      app.wrap(ole)
    rescue => ex
      app.error_proc.call(ex, self)
    end

    # @rbs return Layout
    def active_layout
      ole = ole_obj.ActiveLayout
      app.wrap(ole)
    end

    # @rbs layout: Layout -- layout to make active
    def active_layout=(layout)
      ole_obj.ActiveLayout = layout.to_ole
    end

    def active_space
      ole = ole_obj.ActiveSpace

      if ole == ACAD::AcPaperSpace
        paper_space

      else
        model_space
      end
    end

    # Close the drawing
    # @rbs save: bool -- whether to save the drawing
    def close(save = true)
      # Store the name before marking as closed
      drawing_name = @ole_obj.respond_to?(:Name) ? @ole_obj.Name : "unknown"
      @drawing_closed = true
      
      begin
        @ole_obj.Close(save)
      rescue => ex
        # Instead of just calling error_proc, raise a specific DrawingClose error
        # Use drawing name instead of the drawing object
        raise DrawingClose.new("Failed to close drawing: #{ex.message}", drawing_name)
      ensure
        @ole_obj = nil
      end
    end

    # @rbs name: String -- selection set name to return
    # @rbs return SelectionSet | nil
    def get_selection_set(name)
      ole = get_ole_selection_set(name)
      app.wrap(ole) if ole
    end

    # @rbs return Enumerator[Block]
    # @rbs &: (Block) -> void
    def blocks
      return to_enum(__callee__) unless block_given?
      ole_obj.Blocks.each { |o| yield app.wrap(o) }
    end

    # @rbs return Enumerator[Layout]
    # @rbs &: (Layout) -> void
    def layouts
      return to_enum(__callee__) unless block_given?
      ole_obj.Layouts.each { |o| yield app.wrap(o) }
    end
    # return the layers for the drawing

    # @rbs return Enumerator[Layer]
    # @rbs &: (Layer) -> void
    def layers
      return to_enum(__callee__) unless block_given?

      ole_obj.Layers.each { |o| yield app.wrap(o) }
    end

    def linetypes
      return to_enum(__callee__) unless block_given?
      ole_obj.Linetypes.each { |o| yield app.wrap(o) }
    end

    # @rbs name: String | Layer -- layer name to create
    # @rbs return Acad::Layer
    def create_layer(name, color =  nil)
      if name.class == Autocad::Layer
          name.Color = color if color
        return name
      end
      ole_layer = begin
        ole_obj.Layers.Item(name)
      rescue
        nil
      end
      ole_layer ||= ole_obj.Layers.Add(name)
      ole_layer.Color = color if color
      app.wrap(ole_layer)
    end

    # regen the current drawing
    #  view_ports is fr AcRegenType enum from autocad
    #  [:all, :active]
    #  @rbs view_ports: Symbol -- :all or :active
    #  @rbs return void
    def regen(view_ports = :all)
      vp_type = case view_ports
      when :all then 1
      when :active then 0
      end
      ole_obj.Regen vp_type
    end

    # @rbs return Enumerator[BlockReference] -- all block references in model space
    def model_block_references
      ss = selection_sets.find { it.name == "model_block_references" }
      ss ||= create_selection_set("model_block_references")
      ss.filter do |f|
        f.and(f.model_space, f.block_reference)
      end
      ss.clear
      ss.select
      ss.each
    end

    # @rbs return Enumerator[BlockReference] -- all block references in paper space
    def paper_block_references
      ss = selection_sets.find { it.name == "paper_block_references" }
      ss ||= create_selection_set("paper_block_references")
      ss.filter do |f|
        f.and(f.paper_space, f.block_reference)
      end
      ss.clear
      ss.select
      ss.each
    end

    def select_text_containing(str)
      varname = "@text_containg_#{str}".tr("*", "_")
      ss = if instance_variable_defined?(varname)
        instance_variable_get(varname)
      else
        get_select_text_containing(str)
      end
      ss.clear
      ss.select
      ss.each
    end

    def has_pviewport?
      paper_space.pviewports.count > 0
    end

    def get_select_text_containing(str)
      name = "text_containing_#{str}"
      varname = "@#{name}".tr("*", "_")
      ss = get_selection_set(name)
      ss.delete if ss
      ss = create_selection_set(name) do |ss|
        ss.filter_text_containing(str)
      end
      instance_variable_set(varname, ss)
      ss
    end

    # &: (BlockReference) -> void
    # @rbs return Enumerator[BlockReference]
    def block_references
      return to_enum(__callee__) unless block_given?
      ss = block_reference_selection_set
      ss.clear
      ss.select
      ss.each do |o|
        yield o
      end
    end

    # &: (DimStyle) -> void
    # @rbs return Enumerator[DimStyle] -- enumerator of dimension styles in document
    def dim_styles
      return to_enum(__callee__) unless block_given?
      ole_obj.DimStyles.each { |o| yield app.wrap(o) }
    end

    # &: (TextStyle) -> void
    # @rbs return Enumerator[TextStyle] -- enumerator of text styles in document
    def text_styles
      return to_enum(__callee__) unless block_given?
      ole_obj.TextStyles.each { |o| yield app.wrap(o) }
    end

    # @rbs return SelectionSetAdapter
    def block_reference_selection_set
      @block_reference_selection_set ||= get_block_reference_selection_set
    end

    def get_variable(name)
      ole_obj.GetVariable(name)
    end

    def set_variable(name, value)
      ole_obj.SetVariable(name, value)
    end

    def set_variables(names, values)
      atts = names.zip(values).to_h
      atts.each do |k, v|
        set_variable(k, v)
      end
    end

    def with_system_variables(names, values, &block)
      atts
      current_values = get_variables(names)
      set_variables(names, values)
      yield
    ensure
      set_variables(names, current_values)
    end

    def get_variables(*atts)
      return [] if atts.empty?
      if atts.first.class == Array
        atts = atts.first
      end
      atts.each_with_object([]) do |k, a|
        a << ole_obj.GetVariable(k)
        a
      end
    end
    # @rbs name: String -- the name to call new selection set
    # @rbs return Autocad::SelectionSet | nil
    # def create_selection_set(name, filter: nil)
    #   ss = get_ole_selection_set(name)
    #   ss.Delete if ss
    #   ss = ole_selection_sets.Add(name)
    #   app.wrap(ss)
    # rescue WIN32OLE::RuntimeError
    #   nil
    # end

    # @rbs message: String -- the String to put in Autocad prompt
    def prompt(message)
      utility.Prompt(message)
    end

    # @rbs prompt: String -- the string to prompt the user for String
    # @rbs has_spaces: bool -- whether the string returned can contain spaces
    def get_input_string(prompt: "Enter a string", spaces: true)
      utility.GetString(spaces, prompt)
    rescue => ex
      raise Autocad::Error.new("Error getting string input from user #{ex}")
    end

    # @rbs prompt: String -- the string to prompt the user for Integer
    def get_input_integer(prompt: "Enter a integer")
      utility.GetInteger(prompt)
    rescue => ex
      raise Autocad::Error.new("Error getting integer input from user #{ex}")
    end

    def get_float(prompt: "Enter a float")
      utility.GetReal(prompt)
    rescue => ex
      raise Autocad::Error.new("Error getting float input from user #{ex}")
    end

    # In a running Autocad instance, prompts the user for a point.
    # Uses the prompt argument as the prompt string.
    # If base_point is provided, it is used as the base point and a
    # stretched line is drawn from the base point to the returned point.
    # @rbs prompt: String
    # @rbs base_point: Array, Point3d, nil
    # @rbs return [Point3d]
    def get_point(prompt: "Get point", base_point: nil)
      if base_point
        array_pt = base_point.to_ary.map { |x| x.to_f } unless base_point.nil?
        base_point = WIN32OLE_VARIANT.array([3], WIN32OLE::VARIANT::VT_R8)
        base_point[0] = array_pt[0]
        base_point[1] = array_pt[1]
        base_point[2] = array_pt[2]
      end
      pt = utility.GetPoint(base_point, prompt)
      Point3d.new(pt[0], pt[1], pt[2])
    rescue => ex
      raise Autocad::Error.new("Error getting point input from user #{ex}")
    end

    def get_region
      pt = get_point(prompt: "Specify first corner")
      prompt("X: #{pt.x}, Y: #{pt.y}, Z: #{pt.z}\n")
      point2 = utility.GetCorner(pt.to_ole, "Specify opposite corner: ")
      pt2 = Point3d(point2)
      [pt, pt2]
    end

    # @rbs return Enumerator[SelectionSet] | void
    # @rbs &: (SelectionSet) -> void
    def selection_sets
      return to_enum(__callee__) unless block_given?
      ole_selection_sets.each { |o| yield app.wrap(o) }
    end

    def model_space
      app.wrap ole_obj.ModelSpace
    end

    # @rbs return Enumerator[PlotConfiguration] | void
    # @rbs &: (PlotConfiguration) -> void
    def plot_configurations
      return to_enum(__callee__) unless block_given?
      ole_obj.PlotConfigurations.each { |o| yield app.wrap(o) }
    end

    # @rbs return Enumerator[Layout] | void
    # @rbs &: (Layout) -> void
    def plot_configurations
      return to_enum(__callee__) unless block_given?
      ole_obj.Layouts.each { |o| yield app.wrap(o) }
    end

    def paper_space
      app.wrap ole_obj.PaperSpace
    end

    alias_method :model, :model_space
    alias_method :paper, :paper_space

    def utility
      ole_obj.Utility
    end

    def ole_obj
      if @drawing_closed || @ole_obj.nil?
        # Use a local variable to avoid recursive call to name method
        drawing_name = @ole_obj.respond_to?(:Name) ? @ole_obj.Name : "unknown"
        raise DrawingClose.new("Drawing is closed", drawing_name)
      end
      
      # Check if the ole object is still valid
      begin
        @ole_obj.Name
        @ole_obj
      rescue => e
        @drawing_closed = true
        @ole_obj = nil
        # Use a string directly instead of calling name method
        raise DrawingClose.new("Drawing is no longer valid: #{e.message}", "unknown")
      end
    end

    private

    def get_block_reference_selection_set
      ss = get_selection_set("block_reference") || create_selection_set("block_reference")
      ss.filter do |f|
        f.block_reference
      end
      ss
    end

    # @rbs name: String -- selection set name to return
    # @rbs return SelectionSet | nil
    def get_ole_selection_set(name)
      return nil if ole_selection_sets.Count == 0
      begin
        ole_selection_sets.Item(name)
      rescue
        nil
      end
    end

    def ole_selection_sets
      ole_obj.SelectionSets
    end

    # # @rbs objects: nil | Enumerator[Element] | SelectionSetAdapter | Element
    # # @rbs return Enumerator[Element]
    # def get_objects(objects = nil, prompt: "Select objects")
    #   case objects
    #   in nil
    #   # Create a temporary selection set for user selection
    #   ss = create_selection_set("temp_selection_#{Time.now.to_i}")
    #   self.prompt("#{prompt}\n")
    #   ss.select_on_screen
    #   result = ss.each
    #   ss.delete
    #   result
    #   in Autocad::SelectionSetAdapter
    #   objects.each
    #   in Enumerator
    #   objects
    #   in Array
    #   objects.to_enum
    # else
    #   # Handle single object case by wrapping in an enumerator
    #   [objects].to_enum
    # end
    # rescue => ex
    #   app.error_proc.call(ex, self)
    # end

    # @rbs objects: nil | Enumerator[Element] | SelectionSetAdapter | Element
    # @rbs alignment: Symbol -- :left, :right, :center, :top, :mid, :bottom
    # @rbs return void
    #   def align_objects(objects = nil, alignment: :left)
    #     objects = get_objects(objects, prompt: "Select objects to align")
    #
    #     # Get bounding boxes for all objects
    #     boxes = objects.map do |obj|
    #       begin
    #         obj.bounds
    #       rescue => ex
    #         app.error_proc.call(ex, self)
    #         nil
    #       end
    #     end.compact
    #
    #     return if boxes.empty?
    #
    #     # Calculate reference point based on alignment type
    #     reference = case alignment
    #     when :left
    #       boxes.map { |box| box.left }.min
    #     when :right
    #       boxes.map { |box| box.right }.max
    #     when :center
    #       boxes.map { |box| box.center.x }.sum / boxes.length
    #     when :top
    #       boxes.map { |box| box.top }.max
    #     when :bottom
    #       boxes.map { |box| box.bottom }.min
    #     when :mid
    #       boxes.map { |box| box.center.y }.sum / boxes.length
    #     else
    #       raise ArgumentError, "Invalid alignment type: #{alignment}. Must be :left, :right, :center, :top, :mid, or :bottom"
    #     end
    #
    #     # Move each object to align with reference point
    #     objects.zip(boxes).each do |obj, box|
    #       next unless box
    #
    #       delta = case alignment
    #       when :left
    #         [reference - box.left, 0, 0]
    #       when :right
    #         [reference - box.right, 0, 0]
    #       when :center
    #         [reference - box.center.x, 0, 0]
    #       when :top
    #         [0, reference - box.top, 0]
    #       when :bottom
    #         [0, reference - box.bottom, 0]
    #       when :mid
    #         [0, reference - box.center.y, 0]
    #       end
    #
    #       begin
    #         # Create points for move_ole
    #         pt1 = Point3d(0, 0, 0)
    #         pt2 = Point3d(*delta)
    #         obj.move_ole(pt1.to_ole, pt2.to_ole)
    #       rescue => ex
    #         app.error_proc.call(ex, self)
    #       end
    #     end
    #
    #     regen
    #   end
    #   case objects
    #   in nil
    #   # Create a temporary selection set for user selection
    #   ss = create_selection_set("temp_selection_#{Time.now.to_i}")
    #   self.prompt("#{prompt}\n")
    #   ss.select_on_screen
    #   result = ss.each
    #   ss.delete
    #   result
    #   in Autocad::SelectionSetAdapter
    #   objects.each
    #   in Enumerator
    #   objects
    #   in Array
    #   objects.to_enum
    # else
    #   # Handle single object case by wrapping in an enumerator
    #   [objects].to_enum
    # end
    # rescue => ex
    #   app.error_proc.call(ex, self)
    # end
  end
end
