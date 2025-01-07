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

    def set_system_variables(names, values)
      atts = names.zip(values).to_h
      atts.each do |k, v|
        ole_obj.SetVariable(k, v)
      end
    end

    def faa_title_block
      block_reference_enum.find { |b| b.name == "faatitle" }
    end

    def block_reference_enum
      ss = block_reference_selection_set
      ss.clear
      ss.select
      ss.each
    end

    def block_reference_selection_set
      @block_reference_selection_set ||= get_block_reference_selection_set
    end

    def get_block_reference_selection_set
      ss = get_selection_set("block_reference")
      ss ||= create_selection_set("block_reference") do |ss|
        ss.filter do |f|
          f.block_reference
        end
      end
      ss
    end

    def with_system_variables(names, values, &block)
      atts
      current_values = get_system_variables(names)
      set_system_variables(names, values)
      yield
    ensure
      set_system_variables(names, current_values)
    end

    def get_system_variables(*atts)
      return [] if atts.empty?
      if atts.first.class == Array
        atts = atts.first
      end
      atts.each_with_object([]) do |k, a|
        a << ole_obj.GetVariable(k)
        a
      end
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

    def read_only?
      ole_obj.ReadOnly
    end

    def previously_saved?
      ole_obj.FullFileName != ""
    end

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
      windows_name = app.windows_path(out_name)
      loop do
        print_pdf(windows_name, model:)
        break if out_name.file?
      end
      puts "saved #{windows_name}"
    end

    def pdf_path(name: nil, dir: nil)
      name ||= self.name
      dir = Pathname.new(dir || dirname).expand_path
      dir.mkpath unless dir.directory?
      dir + pdf_name(name)
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

    def print_pdf(print_path, model: false)
      if model
        to_model_space
      else
        to_paper_space
      end
      raise "no plot config" unless pdf_plot_config
      ole_obj.Plot.PlotToFile print_path, pdf_plot_config
    end

    def pdf_plot_config
      app.plot_configs.find { |p| p =~ /faa.+high/i }
    end

    def active_layer
      ole_obj.ActiveLayer
    end

    def active_space
      ole = ole_obj.ActiveSpace
      if ole == ACAD::AcPaperSpace
        PaperSpace.new(ole_obj, app)
      else
        ModelSpace.new(ole_obj, app)
      end
    end

    # Close the drawing
    # @rbs save: bool -- whether to save the drawing
    def close(save = true)
      @drawing_closed = true
      begin
        ole_obj.Close(save)
      rescue
        nil
      end
      @ole_obj = nil
    end

    # @rbs name: String -- selection set name to return
    # @rbs return SelectionSet | nil
    def get_selection_set(name)
      ole = get_ole_selection_set(name)
      app.wrap(ole) if ole
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

    # @rbs return Enumerator[Block]
    # @rbs &: (Block) -> void
    def blocks
      return to_enum(__callee__) unless block_given?
      ole_obj.Blocks.each { |o| yield app.wrap(o) }
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

    # @rbs name: String -- layer name to create
    # @rbs return Acad::Layer
    def create_layer(name, color: nil)
      ole_layer = begin
        ole_obj.Layers.Item(name)
      rescue
        nil
      end
      ole_layer ||= ole_obj.Layers.Add(name)
      ole_layer.Color = color if color
      app.wrap(ole_layer)
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
      pt2 = utility.ole_obj.GetCorner(pt.to_ole, "Specify opposite corner: ")
      [pt, pt2].map { |p| Point3d.new(p[0], p[1], p[2]) }
    end

    # @rbs return Enumerator[SelectionSet] | void
    # @rbs &: (SelectionSet) -> void
    def selection_sets
      return to_enum(__callee__) unless block_given?
      ole_selection_sets.each { |o| yield app.wrap(o) }
    end

    def model_space
      ModelSpace.new(ole_obj.ModelSpace, app)
    end

    def paper_space
      PaperSpace.new(ole_obj.PaperSpace, app)
    end

    alias_method :model, :model_space
    alias_method :paper, :paper_space

    def utility
      ole_obj.Utility
    end

    def ole_obj
      is_ok = true
      begin
        @ole_obj.Name
      rescue
        is_ok = false
      end
      binding.break unless is_ok
      @ole_obj
    end
  end
end
