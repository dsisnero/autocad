# rbs_inline: enabled

module Autocad
  module Common
    # Handle uppercase method calls by forwarding to OLE object
    # @rbs (Symbol, untyped) -> untyped
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
    # @rbs color: Symbol | String | Integer
    # @rbs return Integer
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
    # @rbs index: Integer
    # @rbs return Symbol | Integer
    def self.from_index(index)
      constants.each do |const_name|
        return underscore(const_name).to_sym if const_get(const_name) == index
      end
      index # Return the original index if no matching constant
    end

    # Helper method to convert to snake_case
    # @rbs camel_case: String
    # @rbs return String
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
  # @rbs color: Symbol | String | Integer
  # @rbs return Integer
  def self.color_to_index(color)
    return color if color.is_a?(Integer)
    Color.to_index(color)
  end

  class << self
    # @rbs &: (Autocad::App) -> void
    # @rbs return void
    def run(...)
      App.run(...)
    end

    # @rbs return Pathname
    def root
      ROOT
    end

    # Convert DGN/DWG files to PDF
    # @rbs dir_or_file: String | Pathname
    # @rbs outdir: String | Pathname
    # @rbs mode: :dir | :file
    # @rbs return void
    # @raise [RuntimeError] Invalid mode
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

    # Process currently open drawings
    # @rbs &: (Drawing) -> void
    # @rbs return void
    def with_open_drawings(...)
      run do |app|
        return unless app.has_drawings?
        app.drawings.each do |drawing|
          yield drawing
        end
      end
    end

    # Save all open drawings
    # @rbs dir: String | Pathname
    # @rbs exit: bool
    # @rbs model: bool
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

    # Save current drawing with options
    # @rbs dir: String | Pathname
    # @rbs exit: bool
    # @rbs model: bool
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

    # Save current drawing as PDF
    # @rbs dir: String | Pathname
    # @rbs return void
    def save_current_drawing_as_pdf(dir)
      App.run do |app|
        drawing = app.current_drawing
        drawing.save_as_pdf(dir: dir)
        drawing.close
      end
    end

    # Find drawings in directory
    # @rbs dir: String | Pathname
    # @rbs return Array[Pathname]
    def drawings_in_dir(dir)
      dirpath = Pathname.new(dir).expand_path
      dirpath.glob("*.d{gn,wg,xf}").sort_by { _1.basename(".*").to_s.downcase }
    end

    # Open single drawing
    # @rbs drawing: String | Pathname
    # @rbs return Drawing
    def open_drawing(drawing, ...)
      App.open_drawing(drawing, ...)
    end

    # Process multiple drawings
    # @rbs *files: Array[String | Pathname]
    # @rbs visible: bool
    # @rbs error_proc: (Exception, Drawing) -> void
    # @rbs wait_time: Integer
    # @rbs wait_interval: Float
    # @rbs read_only: bool
    # @rbs &: (Drawing) -> void
    # @rbs return void
    def with_drawings(...)
      App.with_drawings(...)
    end

    # Process drawings in directory
    # @rbs dir: String | Pathname
    # @rbs ...: untyped
    # @rbs return void
    def with_drawings_in_dir(dir, ...)
      drawings = drawings_in_dir(dir)
      with_drawings(drawings, ...)
    end
  end
end
