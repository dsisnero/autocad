# require_relative 'scan/scan_trait'
# require_relative "model_trait"

# require_relative 'ts/tagset_trait'
# require_relative 'graphics'
# require_relative 'ts/instance'

module Autocad
  module ModelTrait
    # Iterate through all elements in the model space
    # @rbs return Enumerator[Autocad::Element]
    # @rbs &: (Autocad::Element) -> void
    def each
      return enum_for(:each) unless block_given?

      @ole_obj.each do |ole|
        yield app.wrap(ole)
      end
    end

    # Check if this model is an external reference
    # @rbs return bool
    def xref?
      @ole_obj.IsXRef
    rescue
      false
    end

    # Attach an external reference to the model
    # @rbs path: String
    # @rbs name: String
    # @rbs pt: Array[Numeric] | Autocad::Point3d
    # @rbs x_scale: Numeric
    # @rbs y_scale: Numeric
    # @rbs z_scale: Numeric
    # @rbs rotation: Numeric
    # @rbs overlay: bool
    # @rbs password: String?
    # @rbs return Autocad::BlockReference?
    def attach_external_reference(path, name:, pt: [0, 0, 0], x_scale: 1.0, y_scale: 1.0, z_scale: 1.0, rotation: 0.0,
      overlay: false, password: nil)
      windows_path = app.windows_path(path)
      pt3d = Point3d.new(insertion_point)
      ole_reference = ole_obj.AttachExternalReference(windows_path, name, pt3d.to_ole, x_scale, y_scale, z_scale,
        rotation, overlay, password)
      app.wrap(ole_reference)
    rescue => e
      app.error_proc.call(e, self)
    end

    # Add a line to the model
    # @rbs pt1: Array[Numeric] | Autocad::Point3d
    # @rbs pt2: Array[Numeric] | Autocad::Point3d
    # @rbs layer: String?
    # @rbs return Autocad::Line?
    def add_line(pt1, pt2, layer: nil)
      pt1 = Point3d.new(pt1)
      pt2 = Point3d.new(pt2)
      ole_line = ole_obj.AddLine(pt1.to_ole, pt2.to_ole)
      if layer
        layer_obj = create_layer(layer)
        ole_line.Layer = layer_obj.name
      end
      app.wrap(ole_line)
    rescue => e
      puts e.message
      nil
    end

    # Get the layout associated with this model
    # @rbs return Autocad::Layout
    def layout
      ole_layout = ole_obj.Layout
      app.wrap(ole_layout)
    end

    # Add an arc to the model
    # @rbs center: Array[Numeric] | Autocad::Point3d
    # @rbs radius: Numeric
    # @rbs start_angle: Numeric
    # @rbs end_angle: Numeric
    # @rbs return Autocad::Arc
    # @raise [Autocad::Error] If arc creation fails
    def add_arc(center, radius, start_angle, end_angle)
      pt = Point3d(center)
      ole_arc = ole_obj.AddArc(pt.to_ole, radius, start_angle, end_angle)
      app.wrap(ole_arc)
    rescue => e
      raise Autocad::Error.new("Error adding arc #{e}")
    end

    # Add a circle to the model
    # @rbs center: Array[Numeric] | Autocad::Point3d
    # @rbs radius: Numeric
    # @rbs return Autocad::Circle
    # @raise [Autocad::Error] If circle creation fails
    def add_circle(center, radius)
      pt = Point3d(center)
      ole_circle = ole_obj.AddCircle(pt.to_ole, radius)
      app.wrap(ole_circle)
    rescue => e
      raise Autocad::Error.new("Error adding circle #{e.message}")
    end

    # Add a rectangular polyline to the model
    # @rbs lower_left: Array[Numeric] | Autocad::Point3d
    # @rbs upper_right: Array[Numeric] | Autocad::Point3d
    # @rbs return Autocad::Element
    # @raise [Autocad::Error] If rectangle creation fails
    def add_rectangle(lower_left, upper_right)
      x1, y1 = Point3d(lower_left).to_xy
      x2, y2 = Point3d(upper_right).to_xy
      pts = [x1, y1, x2, y1, x2, y2, x1, y2, x1, y1]
      pts_variant = WIN32OLE::Variant.new(pts, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)
      ole = ole_obj.AddLightweightPolyline(pts_variant)
      app.wrap(ole)
    rescue => e
      raise Autocad::Error.new("Error adding rectangle #{e}")
    end

    # Add an ellipse to the model
    # @rbs center: Array[Numeric] | Autocad::Point3d
    # @rbs major_axis: Numeric
    # @rbs radius_ratio: Numeric
    # @rbs return Autocad::Ellipse
    # @raise [Autocad::Error] If ellipse creation fails
    def add_ellipse(center, major_axis, radius_ratio)
      pt = Point3d(center)
      ole_ellipse = ole_obj.AddEllipse(pt.to_ole, major_axis, radius_ratio)
      app.wrap(ole_ellipse)
    rescue => e
      raise Autocad::Error.new("Error adding ellipse #{e}")
    end

    # Add a spline to the model
    # @rbs points: Array[Array[Numeric] | Autocad::Point3d]
    # @rbs start_tangent: Array[Numeric] | Autocad::Point3d
    # @rbs end_tangent: Array[Numeric] | Autocad::Point3d
    # @rbs return Autocad::Spline
    # @raise [Autocad::Error] If spline creation fails
    def add_spline(points, start_tangent, end_tangent)
      pts = Point3d.pts_to_array(points)
      pts_variant = Point3d.array_to_ole(pts)

      start_tangent_ole = Point3d.new(start_tangent).to_ole
      end_tangent_ole = Point3d.new(end_tangent).to_ole

      ole = ole_obj.AddSpline(pts_variant, start_tangent_ole, end_tangent_ole)
      app.wrap(ole)
    rescue => e
      raise Autocad::Error.new("Error adding spline #{e.message}")
    end

    # Get the parent drawing document
    # @rbs return Autocad::Drawing
    def drawing
      @drawing ||= ::Autocad::Drawing.from_ole_obj(app, ole_obj.Document)
    end

    private

    # Internal method to create/get a layer
    # @rbs name: String
    # @rbs color: Numeric | Symbol | String?
    # @rbs return Autocad::Layer
    def create_layer(name, color = nil)
      drawing.create_layer(name, color)
    end
  end

  # Paper space container class
  class PaperSpace < Element
    include ModelTrait

    # Add a paper space viewport
    # @rbs center: Array[Numeric] | Autocad::Point3d
    # @rbs width: Numeric
    # @rbs height: Numeric
    # @rbs return Autocad::PViewport
    # @raise [StandardError] If viewport creation fails
    def add_pv_viewport(center, width:, height:)
      center = Point3d(center)
      ole = ole_obj.AddPViewport(center.to_ole, width.to_f, height.to_f)
      if ole
        ole.Display(true)
        ole.ViewportOn = true
        layer = drawing.create_layer('Vport', 9)
        layer.Plottable = false
        ole.Layer = layer.name
        ole.StandardScale = ACAD::AcVpScaleToFit
        app.wrap(ole)
      end
    rescue
      nil
    end

    # Get all paper space viewports
    # @rbs return Array[Autocad::PViewport]
    def pviewports
      each.select { it.pviewport? }
    end

    # Delete all paper space viewports
    # @rbs return void
    def clear_pviewports
      pviewports.each(&:delete)
    end
  end

  # Model space container class
  class ModelSpace < Element
    include ModelTrait
    # Inherits all ModelTrait functionality for model space entities
  end
end
