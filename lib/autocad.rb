module Autocad
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

def Point3d(...)
  Autocad::Point3d.new(...)
end

module Autocad
  ROOT = Pathname(__dir__).parent

  class << self
    # @yield [Autocad::App]
    def run(...)
      App.run(...)
    end

    # @return [Pathname]
    def root
      ROOT
    end

    # @param dir [String] the directory of drawing [dgn,dwg] to convert
    # @param outdir [String] the output dir for converted pdf files
    def dgn2pdf(dir_or_file, outdir: dir_or_file, mode: :dir)
      raise "Mode on of :dir or :file" unless [:dir, :file].include? mode
      if mode == :dir
        drawings = drawings_in_dir(dir_or_file)
        with_drawings(drawings) do |drawing|
          drawing.save_as_pdf(name: drawing.name, dir: outdir)
        end
      else
        open_drawing(dir_or_file) do |drawing|
          drawing.save_as_pdf(name: drawing.name, dir: outdir)
        end
      end
    end

    # save the current drawing
    # @param dir [String,Dir] the dir to save drawing to
    # return [void]
    def save_current_drawing(dir, exit: true)
      if exit
        run do |app|
          drawing = app.current_drawing
          return unless drawing
          drawing.copy(dir: dir)
          drawing.save_as_pdf(dir: dir)
          drawing.close
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
    # @param dir [String,Dir] the dir to save drawing to
    # return [void]
    def save_current_drawing_as_pdf(dir)
      App.run do |app|
        drawing = app.current_drawing
        drawing.save_as_pdf(dir: dir)
        drawing.close
      end
    end

    # gets all dwg and dgn dfiles in a directory
    # @param dir
    def drawings_in_dir(dir)
      dirpath = Pathname.new(dir).expand_path
      dirpath.glob("*.d{gn,wg,xf}").sort_by { _1.basename(".*").to_s.downcase }
    end

    def open_drawing(drawing, ...)
      App.open_drawing(drawing, ...)
    end

    def with_drawings(...)
      App.with_drawings(...)
    end

    def with_drawings_in_dir(dir, ...)
      drawings = drawings_in_dir(dir)
      with_drawings(drawings, ...)
    end
  end
end
