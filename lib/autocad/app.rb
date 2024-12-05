# rbs_inline: enabled

require_relative "event_handler"
require_relative "drawing"
require_relative "paths"
require_relative "element"
require_relative "line"
require_relative "text"
require_relative "viewport"
require_relative "block"
require_relative "block_reference"
require_relative "selection_set"

require "win32ole"
module Windows
  class FileSystem
    def self.windows_path(path)
      obj = new
      obj.windows_path(path)
    end

    # Convert path to windows path
    # @rbs path: String, Pathname the path you want to convert
    def windows_path(path)
      path = path.to_path if path.respond_to? :to_path
      fs_object.GetAbsolutePathName(path.to_str)
    end

    def fs_object
      @fs_object ||= WIN32OLE.new("Scripting.FileSystemObject")
    end
  end
end

module Autocad
  # Your code goes here...

  class App
    include Common
    @default_error_proc = ->(e, f) {
      puts "Couldn't open drawing #{f}" if f
      debug_error if $DEBUG
      raise e
    }

    class << self
      attr_accessor :default_error_proc

      def default_app_options
        {visible: false, error_proc: @default_error_proc, wait_time: 500, wait_interval: 0.5}
      end

      def debug_error
        require "debug"
        binding.break
      end

      # Runs the app, opening the filenames
      # and yielding each open drawing to the
      # supplied block
      # it automatically closes the drawing and
      # the app when done
      #
      # [source]
      # dir = Pathname.new('C:/templates')
      # drawings = Pathname.glob(dir + '/**/*.dgn')
      # App.with_drawings(drawings) do |drawing|
      #   drawing.save_as_pdf(dir: 'c:/output/')
      # end
      #
      # @rbs *files: Array[String|Pathname]
      # @rbs visible: bool -- show the app window
      # @rbs error_proc: (Exception, Drawing) -> void
      # @rbs wait_time: Integer -- the total amount of time to wait to open file (500)
      # @rbs wait_interval: Float -- the amount of time to wait between attempts (0.5)
      # @rbs read_only: bool
      # @rbs &: (Drawing) -> void
      def with_drawings(*files, visible: false, error_proc: @default_error_proc,
        wait_time: 500, wait_interval: 0.5, read_only: false, &block)
        # drawing_options = default_drawing_options.merge(options)
        # app_options = default_app_options
        files = files[0] if files[0].is_a? Array
        begin
          the_app = new(visible:, error_proc:, wait_time:, wait_interval:)
          files_enum = files.each
          loop do
            file = files_enum.next
            puts "opening #{file}.."
            begin
              the_app.open_drawing(file, read_only:, wait_time:, wait_interval:, error_proc:, &block)
              the_app.ole_obj.ole_methods # check if server still open
            rescue => e
              raise e unless error_proc

              error_proc.call(e, file)
              the_app = new(visible: opt_visible)
            end
          end
        ensure
          the_app&.quit
          the_app = nil
        end
      end

      # gets all dwg and dgn files in the directory given by
      # dir_or_file or gets the file given by dir_or_file
      # and saves them as pdf files in the outdir
      # @rbs dir_or_file: String the directory of drawing [dgn,dwg] to convert
      # @rbs outdir: String the output dir for converted pdf files
      # @rbs return void
      def dwg2pdf(dir_or_file, outdir: dir_or_file, mode: :dir)
        raise "Mode on of :dir or :file" unless [:dir, :file].include? mode
        if mode == :dir
          drawings = drawings_in_dir(dir_or_file)
          with_drawings(drawings, read_only: true) do |drawing|
            drawing.save_as_pdf(name: drawing.name, dir: outdir)
          end
        else
          open_drawing(dir_or_file) do |drawing|
            drawing.save_as_pdf(name: drawing.name, dir: outdir)
          end
        end
      end

      # Initialize an instance of app with the options
      # @rbs : Hash] options the options to create the app with
      # @option options bool :visible Is the app visible
      #
      # [source]
      # ----
      # App.run do |app|
      #   drawing = app.open_drawing('test.dgn')
      #   drawing.scan_all_text do |model,text|
      #   puts "#{model} #{text}"
      #   end
      # end
      # @rbs options: Hash[Symbol,Object]
      # @rbs &: (App) -> void -- the_app yields the instanciated app
      def run(options = {}) #: void
        opts = default_app_options.merge(options)
        err_fn = opts.fetch(:error_proc, default_error_proc)
        begin
          the_app = new(**opts)
          # binding.break if the_app.nil?
          yield the_app
        rescue => e
          if e.respond_to? :drawing
            err_fn.call(e, e.drawing)
          else
            err_fn.call(e, nil)
          end
        ensure
          the_app&.quit
          GC.start
        end
      end

      # Calls #run to get an app instance then call open drawing with
      # that app
      # (see #open_drawing)
      # @rbs &block: { (Drawing) -> void }
      def open_drawing(drawing, **options, &block) #: void
        run(**options) do |app|
          app.open_drawing(drawing, **options, &block)
        end
      end
    end

    # @rbs return bool -- true if there is an active drawing
    def active_drawing?
      ole_obj.Documents.count > 0
    end

    # @rbs return Drawing | nil -- returns drawing if active_drawing
    def active_drawing
      return unless active_drawing?
      ole = ole_obj.ActiveDocument
      drawing_from_ole(ole)
    end

    def drawing_from_ole(ole) #: Drawing
      Drawing.new(self, ole)
    end

    attr_reader :error_proc, :visible, :logger

    # Constructor for app
    # @rbs visible: bool -- do you want the app to be visible
    # @rbs event_handler: EventHandler
    def initialize(visible: true, error_proc: self.class.default_error_proc, event_handler: default_event_handler, wait_interval: nil, wait_time: nil)
      @visible = visible
      @logger = Logger.new("autocad.log")
      @event_handler = event_handler
      @error_proc = error_proc
      @ole_obj, @app_event = init_ole_and_app_event(visible: @visible, event_handler: @event_handler, tries: 5,
        sleep_duration: 0.5)
      @run_loop = true
      @windows = Windows::FileSystem.new
      #  make_visible(visible)
      @scanners = {}
    rescue => e
      @error_proc.call(e, nil)
    end

    def windows_path(path)
      @windows.windows_path(path)
    end

    def wrap(item, cell = nil)
      Element.convert_item(item, self, cell)
    end

    # the default EventHandler
    #
    # @rbs return EventHandler -- returns the default EventHandler
    def default_event_handler
      event_handler = EventHandler.new
      # event_handler.add_handler("BeginOpen") do |*args|
      #   puts "begining opening drawing #{args}"
      # end
      event_handler.add_handler("EndOpen") do |*args|
        puts "drawing #{args} opened"
        @drawing_opened = true
      end
      event_handler.add_handler("BeginDocClose") do |*args|
        @drawing_opened = false
        puts "drawing #{args} closed"
      end

      event_handler.add_handler("NewDrawing") do |*args|
        @drawing_opened = true
        puts "drawing #{args} created"
      end
      event_handler
    end

    def default_app_options
      self.class.default_app_options
    end

    # register an handler
    #
    # @rbs event: String -- event to registor for
    def register_handler(event, &)
      @event_handler.add_handler(event, &) unless event == "OnQuit"
    end

    #
    # return a Handler
    #
    # @rbs : String,Symbol] event the event key
    #
    # @rbs return Proc returns the Proc given by event name
    #
    def get_handler(event)
      @event_handler.get_handler(event)
    end

    def load_constants(ole)
      WIN32OLE.const_load(ole, ACAD) unless ACAD.constants.size > 0
    end

    def run_loop
      WIN32OLE_EVENT.message_loop if @run_loop
    end

    def stop_loop
      @run_loop = false
    end

    def exit_message_loop
      puts "Autocad exiting..."
      @run_loop = false
    end

    def visible?
      @visible
    end

    def visible=(value)
      make_visible !!value
    end

    def make_visible(visible)
      @visible = visible
      begin
        @ole_obj.Visible = visible
        true
      rescue
        false
      end
    end

    def ole_obj
      is_ok = true
      begin
        @ole_obj.Visible
      rescue
        is_ok = false
      end

      @ole_obj, @app_event = init_ole_and_app_event(visible: @visible, event_handler: @event_handler, tries: 3) unless is_ok

      @ole_obj
    end

    def quit
      close_all_drawings
      @ole_obj&.Quit
    rescue
      nil
    end

    def close_all_drawings
      return unless @ole_obj
      until @ole_obj.Documents.Count == 0
        begin
          @ole_obj.ActiveDocument.Close
        rescue
          break
        end
      end
    end

    def close_active_drawing
      drawing = active_drawing
      drawing&.close
    end

    # create a new drawing
    #
    # @rbs filename: String | Pathname -- The name of the drawing.
    # @rbs seedfile: String -- The name of the seed file.
    #  should not include a path. The default ggextension is ".dgn".
    #  Typical values are "seed2d" or "seed3d".
    # @rbs open: bool -- If the open argument is True,
    #   CreateDesignFile returns the newly-opened DesignFile object;
    #   this is the same value as ActiveDesignFile. If the Open argument is False,
    #   CreateDesignFile returns Nothing.
    # @rbs returns Drawing -- returns the new drawing
    def new_drawing(filename, open: true, options: {}, &block)
      opts = default_app_options.merge(options)
      err_fn = opts.fetch(:error_proc, error_proc)
      file_path = Pathname.new(filename).expand_path
      raise ExistingFile, file_path if file_path.exist?

      # drawing_name = normalize_name(filename)
      # seedfile = determine_seed(seedfile)
      # binding.break unless seedfile
      windows_name = windows_path(filename)
      ole = new_ole_drawing(windows_name, open: open, wait_time: opts[:wait_time], wait_interval: opts[:wait_interval])
      drawing = drawing_from_ole(ole)
      return drawing unless block

      begin
        yield drawing
      rescue DrawingError => e
        err_fn.call(e, e.drawing)
      rescue => e
        err_fn.call(e, file_path)
      ensure
        drawing.close
      end
    end

    # open the drawing
    # @rbs filename: String the name of the file to open
    # @rbs : bool :read_only  (false)
    # @rbs wait_time: Integer -- the total amount of time to wait to open file (500)
    # @rbs wait_interval: Float -- the amount of time in seconds to wait before retry (0.5)
    # @rbs error_proc: Proc -- a proc to run
    # @yield [Drawing] drawing
    # @rbs return void
    def open_drawing(filename, read_only: false, wait_time: nil,
      wait_interval: nil, error_proc: nil, &block)
      file_path = Pathname.new(filename).expand_path
      raise FileNotFound.new(file_path) unless file_path.file?

      begin
        ole = ole_open_drawing(windows_path(filename), read_only:, wait_time:, wait_interval:)
      rescue DrawingError => e
        raise e unless err_fn

        err_fn.call(e, e.drawing)
      end
      drawing = drawing_from_ole(ole)
      return drawing unless block_given?

      begin
        yield drawing
      rescue => e
        raise e unless err_fn
        err_fn.call(e, filename)
      ensure
        drawing.close
      end
    end

    alias_method :doc, :active_drawing

    alias_method :current_drawing, :active_drawing

    def model_space
      doc_ole.ModelSpace
    end

    alias_method :model, :model_space

    def prompt(message)
      doc_ole.Utility.prompt(message)
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
      pt = doc_ole.Utility.GetPoint(base_point, prompt)
      Point3d.new(pt[0], pt[1], pt[2])
    end

    # In autocad prompts the user for a selection.
    # @rbs prompt: String the prompt that displays in Autocad
    # @rbs name: String the name of the selection
    # @rbs return [SelectionSet]
    def get_selection(prompt: "Select objects", name: "_SS1")
      prompt(prompt)
      begin
        doc_ole.SelectionSets.Item(name).Delete
      rescue
        logger.debug("Delete selection failed")
      end

      selection = doc_ole.SelectionSets.Add(name)
      selection.SelectOnScreen
      selection
    end

    def has_documents?
      ole_obj.Documents.Count > 0
    end

    # @rbs return [bool] true
    def drawing_opened?
      @drawing_opened
    end

    # @rbs return [Pathname] Autocad Files.TemplateDwgPath
    def templates_path
      Pathname.new(ole_preferences_files.TemplateDwgPath)
    end

    def templates
      return enum_for(:templates) unless block_given?

      templates_path.children.each do |template|
        yield template if template.file?
      end
    end

    # Set Autocad Files.TemplateDwgPath
    # @rbs path: Pathname, String the location on disk for Autocad templates
    def template_path=(path)
      ole_preferences_files.TemplateDwgPath = path.to_s
    end

    # @rbs return [Array<Pathname>] all paths in Files.SupportPath
    def support_paths
      ole_preferences_files.SupportPath.split(";").map { |f| Pathname.new(f) }
    end

    # @rbs return [Array<Pathname>] all paths in Files.PrinterConfigPath
    def printer_config_paths
      ole_preferences_files.PrinterConfigPath.split(";").map { |f| Pathname.new(f) }
    end

    # from the printer_config_paths, return all plotcfg files
    # @rbs return [Enumerator[String]]
    def plot_configs
      return enum_for(:plot_configs) unless block_given?
      printer_config_paths.each do |path|
        path.children.each do |plot|
          yield plot.to_s if plot.file?
        end
      end
    end

    private

    def ole_preferences_files
      @ole_preferences_files ||= ole_obj.Preferences.Files
    end

    def send_command(command)
      ole_obj.SendCommand command
    end

    def init_ole_and_app_event(visible: @visible, event_handler: @event_handler, tries: 5, sleep_duration: 1)
      ole = nil
      begin
        ole = WIN32OLE.connect("Autocad.Application")
      rescue WIN32OLERuntimeError
        ole = WIN32OLE.new("Autocad.Application")
      end

      sleep(sleep_duration)
      # ole.Visible = visible
      # ole.IsProcessLocked = true
      load_constants(ole)
      app_event = WIN32OLE_EVENT.new(ole)
      app_event.handler = event_handler
      [ole, app_event]
    rescue => e
      tries -= 1
      sleep_duration += 1.5
      puts "Error: #{e}. #{tries} tries left."
      retry if tries.positive?
      raise e, "unable to init ole app"
    end

    def doc_ole
      ole_obj.ActiveDocument
    end

    def new_ole_drawing(filename, open: true, wait_time: 500, wait_interval: 0.5)
      ole = ole_obj.Documents.add(filename)
      wait_drawing_opened(wait_time, wait_interval)
      return ole if drawing_opened?
      raise DrawingError.new("New drawing not opened in #{wait_time} seconds", filename)
    end

    def ole_open_drawing(filename, read_only: false, wait_time: 500, wait_interval: 0.5)
      ole = ole_obj.Documents.Open(filename, read_only)
      wait_drawing_opened(wait_time: wait_time, wait_interval: wait_interval)
      return ole if drawing_opened?
      raise DrawingError.new("drewing not opened in #{wait_time}", path) unless drawing_opened?
    end

    def wait_drawing_opened(secs, interval = 1)
      elapsed = 0
      while !drawing_opened? && elapsed <= secs
        elapsed += interval
        sleep(interval)
        run_loop
      end
    end
  end
end
