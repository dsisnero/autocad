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

module Autocad
  module Color
    # Standard AutoCAD color indices
    Red = 1
    Yellow = 2
    Green = 3
    Cyan = 4
    Blue = 5
    Magenta = 6
    White = 7
    Black = 0

    # Additional common colors
    Gray = 8
    LightGray = 9
    DarkRed = 10
    DarkGreen = 96
    DarkBlue = 174
    Orange = 30
    Purple = 200
    Brown = 35

    # Convert a color symbol or name to its integer value
    # @param color [Symbol, String, Integer] color name or index
    # @return [Integer] AutoCAD color index
    def self.to_index(color)
      return color if color.is_a?(Integer)
      
      # Handle both camelCase and snake_case in symbols and strings
      color_str = color.to_s
      
      # Try direct match first (for exact constant names)
      constants.each do |const_name|
        return const_get(const_name) if const_name.to_s.downcase == color_str.downcase
      end
      
      # Try normalized version (convert snake_case to CamelCase)
      normalized = color_str.split('_').map(&:capitalize).join
      constants.each do |const_name|
        return const_get(const_name) if const_name.to_s.downcase == normalized.downcase
      end
      
      raise ArgumentError, "Unknown color: #{color}. Use a valid color name or integer index."
    end
    
    # Convert an integer color index to a symbolic name if possible
    # @param index [Integer] AutoCAD color index
    # @return [Symbol, Integer] Color name as symbol or original index if no name exists
    def self.from_index(index)
      constants.each do |const_name|
        return underscore(const_name).to_sym if const_get(const_name) == index
      end
      index # Return the original index if no matching constant
    end
    
    # Helper method to convert to snake_case
    def self.underscore(camel_case)
      camel_case.to_s.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                .downcase
    end
  end
end

module ACAD
  # Keep the module for backward compatibility
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

  # Convert a color value (symbol, string, or integer) to an AutoCAD color index
  # @param color [Symbol, String, Integer] color name or index
  # @return [Integer] AutoCAD color index
  def self.color_to_index(color)
    return color if color.is_a?(Integer)
    Color.to_index(color)
  end

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
        open_drawing(dir_or_file) do |drawing|
          drawing.save_as_pdf(name: drawing.name, dir: outdir)
        end
      end
    end

    # runs autocad app and yields each open drawing
    # @rbs &: (Drawing) -> void
    # @rbs return void
    def with_open_drawings(...) #: void
      run do |app|
        return unless app.has_drawings?
        app.drawings.each do |drawing|
          yield drawing
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
