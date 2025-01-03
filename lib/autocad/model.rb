# require_relative 'scan/scan_trait'
# require_relative "model_trait"

# require_relative 'ts/tagset_trait'
# require_relative 'graphics'
# require_relative 'ts/instance'

module Autocad
  module ModelTrait
    def each
      return enum_for(:each) unless block_given?

      @ole_obj.each do |ole|
        yield app.wrap(ole)
      end
    end

    # @rbs pt1: Autocad::Point3d
    # @rbs return Autocad::Line
    def add_line(pt1, pt2, layer: nil)
      pt1 = Point3d.new(pt1)
      pt2 = Point3d.new(pt2)
      ole_line = ole_obj.AddLine(pt1.to_ole, pt2.to_ole)
      if layer
        layer = app.create_layer(layer)
        ole_line.layer = layer.ole_obj
      end
      app.wrap(ole_line)
    rescue ex
      puts ex.message
    end

    # @rbs center: [] | Point3d -- center of circle
    # @rbs radius:
    def add_circle(center, radius)
      pt = Point3d(center)
      ole_circle = ole_obj.AddCircle(pt.to_ole, radius)
      app.wrap(ole_circle)
    rescue
      raise Autocad::Error.new('Error adding circle #{ex}')
    end

    def add_rectangle(upper_left, lower_right)
      x1, y1, _z = Point3d(upper_left).to_a
      x2, y2, _z2 = Point3d(lower_right)
      pts = [x1, y1, x2, y1, x2, y1, x2, y2]
      pts_variant = WIN32OLE::Variant.new(pts, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)
      ole = ole_obj.AddLightweightPolyline(pts_variant)
      app.wrap(ole)
    rescue => e
      raise Autocad::Error.new("Error adding rectangle #{e}")
    end

    def add_spline(points)
      pts = Point3d.pts_to_array(points)
      pts_variant = Point3d.array_to_ole(pts)
      ole = ole_obj.AddSpline(pts_variant)
      puts "pts #{pts}"
      puts "pts_variant #{pts_variant.class} #{pts_variant}"
      app.wrap(ole)
    rescue => e
      raise Autocad::Error.new("Error adding spline #{e}")
    end

    def drawing
      @drawing ||= ::Autocad::Drawing.from_ole_obj(app, ole_obj.Document)
    end
  end

  class PaperSpace
    include ModelTrait
    attr_reader :app, :ole_obj

    def initialize(ole, app)
      @ole_obj = ole
      @app = app
    end
  end

  class ModelSpace
    include ModelTrait
    attr_reader :app, :ole_obj

    def initialize(ole, app)
      @ole_obj = ole
      @app = app
    end
  end
end
