require_relative "event_handler"
module Autocad
  class Drawing
    attr_reader :app

    def initialize(app, ole)
      @app = app
      @ole_obj = ole
      @app_event = WIN32OLE_EVENT.new(ole)
    end

    def event_handler
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

    # register an handler
    #
    # @param [String] event key for handler
    # @param [<Type>] &block <description>
    #
    # @return [<Type>] <description>
    #
    def register_handler(event, &)
      @event_handler.add_handler(event, &) unless event == "OnQuit"
    end

    # save the drawing as a pdf file
    # if the name or directory is given it uses
    # those params. If not it uses the drawing name
    # and the drawing directory
    # @param name - the name of the file
    # @param dir - the directory to save the drawing
    # @return [void]
    def save_as_pdf(name: nil, dir: nil, model: false)
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
      dir = Pathname(dir || dirname).expand_path
      dir.mkpath unless dir.directory?
      dir + pdf_name(name)
    end

    # Return the pdf name for the drawing.
    #
    # If a name is provided use the name provided otherwise use the drawing name
    #
    # @param name [String, nil] @return a Pathname from the name or drawing name
    def pdf_name(name = nil)
      name ||= self.name
      Pathname(name).sub_ext(".pdf")
    end

    # copy the drawing
    # @param [String] name of the file
    # @param [String,Pathname] dir
    def copy(name: nil, dir: nil)
      if dir.nil?
        lname = name || copy_name
        dir_path = dirname
      else
        lname = name || self.name
        dir_path = Pathname(dir)
      end
      copy_path = dir_path + lname
      FileUtils.copy path.to_s, copy_path.to_s, verbose: true
    end

    # If you copy the file the name to use
    # @param backup_str [String] the bqckup string to use
    def copy_name(backup_str = ".copy")
      lname = name.dup
      ext = File.extname(lname)
      name = "#{File.basename(lname, ext)}#{backup_str}#{ext}"
    end

    def paper_space?
      ole_obj.ActiveSpace == ACAD::AcPaperSpace
    end

    def model_space?
      ole_obj.ActiveSpace == ACAD::AcModelSpace
    end

    def to_paper_space
      ole_obj.ActiveSpace = ACAD::AcPaperSpace
    end

    def to_model_space
      ole_obj.ActiveSpace = ACAD::AcModelSpace
    end

    # @return [String] the name of the drawing
    def name
      ole_obj.Name
    end

    # @return [Pathname] the name as Pathname
    def basename
      Pathname(name)
    end

    # @return [Pathname] the directory of the file
    def dirname
      Pathname(ole_obj.Path).expand_path
    end

    # @return [Pathname] the complete path of file
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

    # Close the drawing
    def close
      @drawing_closed = true
      begin
        ole_obj.Close
      rescue
        nil
      end
      @ole_obj = nil
    end

    def close
      ole_obj.Close
    end

    def model_space
      ole_obj.ModelSpace
    end

    alias_method :model, :model_space

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
