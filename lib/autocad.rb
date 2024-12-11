# rbs_inline: enabled

module Autocad
  module Common
    def method_missing(method, ...)
      if /^[A-Z]/.match?(method.to_s)
        ole_obj.send(method, ...)
      else
        super
      end
    end
  end
end

module ACAD
end

require "logger"
require "autocad/version"
require "win32ole"
require "pathname"
require "autocad/app"
require "autocad/errors"
require "autocad/point3d"
require "autocad/layer"
require "autocad/message_box"

def Point3d(...)
  Autocad::Point3d.new(...)
end

module Autocad
  ROOT = Pathname.new(__dir__).parent

  class << self
    # @yield [Autocad::App]
    def run(...) #: void
      App.run(...)
    end

    # @return [Pathname]
    def root #:Pathname
      ROOT
    end

    # @rbs dir: String -- the directory of drawing dgn|dwg -- to convert
    # @rbs outdir: String -- the output dir for converted pdf files
    def dgn2pdf(dir_or_file, outdir: dir_or_file, mode: :dir)
      raise "Mode on of :dir or :file" unless [:dir, :file].include? mode
      if mode == :dir
        drawings = drawings_in_dir(dir_or_file)
        with_drawings(drawings) do |drawing|
          drawing.save_as_pdf(name: drawing.name, dir: outdir)
        end
      else
        open_drawing(dir_or_file, read_only: true) do |drawing|
          drawing.save_as_pdf(name: drawing.name, dir: outdir)
        end
      end
    end

    # save the current drawing
    # @rbs dir: String|Pathname -- the dir to save drawing to
    # @rbs exit: bool -- whether to exit afterwards or start irb
    # @rbs model: bool -- prints model space instead of paperspace in pdf document
    # @rbs return void
    def save_open_drawings(dir: Pathname.getwd, exit: true, model: false)
      if exit
        run do |app|
          return unless app.has_drawings?
          drawings = app.drawings
          drawings.each do |d|
            d.copy(dir:)
            d.save_as_pdf(dir:, model:)
            d.close(false)
          end
        end
      else
        app = App.new
        return unless app.has_drawings?
        drawings = app.drawings
        drawings.each do |d|
          d.copy(dir:)
          d.save_as_pdf(dir:, model:)
          # d.close(false)
        end
        app
      end
    end

    # save the current drawing
    # @rbs dir: String|Dir -- the dir to save drawing to
    # @rbs exit: bool -- whether to exit afterwards or start irb
    # @rbs model: bool -- prints model space in pdf document
    # @rbs return void
    def save_current_drawing(dir, exit: true, model: false)
      if exit
        run do |app|
          drawing = app.current_drawing
          return unless drawing
          drawing.copy(dir: dir)
          drawing.save_as_pdf(dir:, model:)
          drawing.close(false)
        end
      else
        app = App.new
        drawing = app.current_drawing
        return unless drawing
        drawing.copy(dir: dir)
        drawing.save_as_pdf(dir: dir)
        app
      end
    end

    # save the current drawing as pdf
    # @rbs dir: String|Dir -- the dir to save drawing to
    # @rbs return void
    def save_current_drawing_as_pdf(dir)
      App.run do |app|
        drawing = app.current_drawing
        drawing.save_as_pdf(dir: dir)
        drawing.close
      end
    end

    # gets all dwg and dgn dfiles in a directory
    # @rbs dir: String|Pathname
    def drawings_in_dir(dir)
      dirpath = Pathname.new(dir).expand_path
      dirpath.glob("*.d{gn,wg,xf}").sort_by { _1.basename(".*").to_s.downcase }
    end

    def open_drawing(drawing, ...)
      App.open_drawing(drawing, ...)
    end

    # Runs the app, opening the filenames
    # and yielding each open drawing to the
    # supplied block
    # it automatically closes the drawing and
    # the app when done
    #
    # @rbs *files: Array[String|Pathname]
    # @rbs visible: bool -- show the app window
    # @rbs error_proc: (Exception, Drawing) -> void
    # @rbs wait_time: Integer -- the total amount of time to wait to open file (500)
    # @rbs wait_interval: Float -- the amount of time to wait between attempts (0.5)
    # @rbs read_only: bool
    # @rbs &: (Drawing) -> void
    def with_drawings(...)
      App.with_drawings(...)
    end

    # Finds the drawing in dir and calls with_drawing forwarding all params
    # @rbs dir: String|Pathname -- directory to search for drawings
    def with_drawings_in_dir(dir, ...)
      drawings = drawings_in_dir(dir)
      with_drawings(drawings, ...)
    end
  end
end
