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

    def xref?
      @ole_obj.IsXRef
    rescue StandardError
      false
    end

    # RetVal = object.AttachExternalReference(PathName, Name, InsertionPoint, XScale, YScale, ZScale, Rotation, Overlay [, Password])
    #

    def attach_external_reference(path, name:, pt: [0, 0, 0], x_scale: 1.0, y_scale: 1.0, z_scale: 1.0, rotation: 0.0,
                                  overlay: false, password: nil)
      windows_path = app.windows_path(path)
      pt3d = Point3d.new(insertion_point)
      ole_reference = ole_obj.AttachExternalReference(windows_path, name, pt3d.to_ole, x_scale, y_scale, z_scale,
                                                      rotation, overlay, password)
      app.wrap(ole_reference)
    rescue StandardError => e
      app.error_proc.call(e, self)
    end

    # @rbs pt1: Autocad::Point3d
    # @rbs return Autocad::Line
    def add_line(pt1, pt2, layer: nil)
      pt1 = Point3d.new(pt1)
      pt2 = Point3d.new(pt2)
      ole_line = ole_obj.AddLine(pt1.to_ole, pt2.to_ole)
      if layer
        layer = create_layer(layer)
        ole_line.layer = layer.ole_obj
      end
      app.wrap(ole_line)
    rescue StandardError => e
      puts e.message
    end

    def layout
      ole_layout = ole_obj.Layout
      app.wrap(ole_layout)
    end

    # add an arc to the model
    # @rbs center: [] | Point3d -- center of arc
    # @rbs radius: Float -- radius of arc
    # @rbs start_angle: Float -- start angle of arc
    # @rbs end_angle: Float -- end angle of arc
    # @rbs return Autocad::Arc
    def add_arc(center, radius, start_angle, end_angle)
      pt = Point3d(center)
      ole_arc = ole_obj.AddArc(pt.to_ole, radius, start_angle, end_angle)
      app.wrap(ole_arc)
    rescue StandardError => e
      raise Autocad::Error.new("Error adding arc #{e}")
    end

    # @rbs center: [] | Point3d -- center of circle
    # @rbs radius: Numeric -- radius of the circle
    # @rbs return Autocad::Element -- the created circle
    def add_circle(center, radius)
      pt = Point3d(center)
      ole_circle = ole_obj.AddCircle(pt.to_ole, radius)
      app.wrap(ole_circle)
    rescue StandardError => e
      raise Autocad::Error.new("Error adding circle #{e.message}")
    end

    def add_rectangle(lower_left, upper_right)
      x1, y1 = Point3d(lower_left).to_xy
      x2, y2 = Point3d(upper_right).to_xy
      pts = [x1, y1, x2, y1, x2, y2, x1, y2, x1, y1]
      pts_variant = WIN32OLE::Variant.new(pts, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)
      ole = ole_obj.AddLightweightPolyline(pts_variant)
      app.wrap(ole)
    rescue StandardError => e
      raise Autocad::Error.new("Error adding rectangle #{e}")
    end

    # add an ellilpse to the model
    # @rbs center: [] | Point3d -- center of ellipse
    # @rbs major_axis: Float -- major axis of ellipse
    # @rbs radius_ratio: Float -- ratio of major axis to minor axis , a value of 1 is a circle
    # @return Autocad::Ellipse
    def add_ellipse(center, major_axis, radius_ratio)
      pt = Point3d(center)
      ole_ellipse = ole_obj.AddEllipse(pt.to_ole, major_axis, radius_ratio)
      app.wrap(ole_ellipse)
    rescue StandardError => e
      raise Autocad::Error.new("Error adding ellipse #{e}")
    end

    def add_spline(points, start_tangent, end_tangent)
      pts = Point3d.pts_to_array(points)
      pts_variant = Point3d.array_to_ole(pts)

      start_tangent_ole = Point3d.new(start_tangent).to_ole
      end_tangent_ole = Point3d.new(end_tangent).to_ole

      ole = ole_obj.AddSpline(pts_variant, start_tangent_ole, end_tangent_ole)
      app.wrap(ole)
    rescue StandardError => e
      raise Autocad::Error.new("Error adding spline #{e.message}")
    end

    def drawing
      @drawing ||= ::Autocad::Drawing.from_ole_obj(app, ole_obj.Document)
    end

    # @rbs return Autocad::Layout -- the layout for the model
    def layout
      ole = ole_obj.Layout
      app.wrap(ole)
    rescue StandardError => e
      app.error_proc.call(e, self)
    end

    private

    def create_layer(name, color = nil)
      drawing.create_layer(name, color)
    end
  end

  class PaperSpace < Element
    include ModelTrait

    def add_pv_viewport(center, width:, height:)
      center = Point3d(center)
      ole = ole_obj.AddPViewport(center.to_ole, width.to_f, height.to_f)
      ole.Display(true)
      ole.ViewportOn = true
      ole.StandardScale = ACAD::AcVpScaleToFit
      app.wrap(ole)
    rescue StandardError => e
      binding.irb
    end

    def pviewports
      each.select { it.pviewport? }
    end

    def clear_pviewports
      pviewports.each(&:delete)
    end
  end

  class ModelSpace < Element
    include ModelTrait
  end
end
