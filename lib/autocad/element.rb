# rbs_inline: enabled
require_relative "bounding_box"
# require "autocad/property_handler"

class WIN32OLE
  def to_ole
    self
  end
end

module Autocad
end

module Autocad
  module AcadEntity
    def layer
      ole_obj.Layer
    end

    def layer=(name)
      ole_obj.Layer = name
    end

    def line_type
      ole_obj.LineType
    end

    def line_type=(name)
      ole_obj.LineType = name
    end

    def visible?
      ole_obj.Visible
    end

    def copy
    end

    def intersects_with(obj)
    end

    def mirror
    end

    def move_to
    end

    def transform_by(matrix)
    end
  end

  module ElementTrait
    # @rbs return nil| Drawing
    def drawing
      app.current_drawing
    end

    def block_reference?
      false
    end

    # def bounds
    #   minpoint = WIN32OLE::Variant.new([0.0, 0.0, 0.0], WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)
    #   maxpoint = WIN32OLE::Variant.new([0.0, 0.0, 0.0], WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)
    #   
    #   ole_obj.GetBoundingBox(minpoint, maxpoint)
    #   
    #   min_pt = Point3d.new(minpoint[0], minpoint[1], minpoint[2])
    #   max_pt = Point3d.new(maxpoint[0], maxpoint[1], maxpoint[2])
    #   
    #   BoundingBox.from_min_max(min_pt, max_pt)
    # rescue => e
    #   raise Autocad::Error.new("Error getting bounds: #{e.message}")
    # end

    def bounds
      begin
        # Try different approaches based on object type
        if ole_obj.respond_to?(:Coordinates)
          # For objects like lines that have Coordinates property
          coords = ole_obj.Coordinates
          
          # Find min and max values
          x_values = []
          y_values = []
          z_values = []
          
          (0...coords.size).step(3) do |i|
            x_values << coords[i]
            y_values << coords[i+1]
            z_values << coords[i+2] if i+2 < coords.size
          end
          
          min_pt = Point3d.new(x_values.min, y_values.min, z_values.min || 0)
          max_pt = Point3d.new(x_values.max, y_values.max, z_values.max || 0)
          
          BoundingBox.from_min_max(min_pt, max_pt)
        elsif ole_obj.respond_to?(:Center) && ole_obj.respond_to?(:Radius)
          # For circles
          center = Point3d.new(ole_obj.Center)
          radius = ole_obj.Radius
          
          min_pt = Point3d.new(center.x - radius, center.y - radius, center.z)
          max_pt = Point3d.new(center.x + radius, center.y + radius, center.z)
          
          BoundingBox.from_min_max(min_pt, max_pt)
        elsif ole_obj.respond_to?(:StartPoint) && ole_obj.respond_to?(:EndPoint)
          # For lines with start and end points
          start_pt = Point3d.new(ole_obj.StartPoint)
          end_pt = Point3d.new(ole_obj.EndPoint)
          
          min_x = [start_pt.x, end_pt.x].min
          min_y = [start_pt.y, end_pt.y].min
          min_z = [start_pt.z, end_pt.z].min
          
          max_x = [start_pt.x, end_pt.x].max
          max_y = [start_pt.y, end_pt.y].max
          max_z = [start_pt.z, end_pt.z].max
          
          min_pt = Point3d.new(min_x, min_y, min_z)
          max_pt = Point3d.new(max_x, max_y, max_z)
          
          BoundingBox.from_min_max(min_pt, max_pt)
        elsif ole_obj.respond_to?(:GetBoundingBox)
          # Last resort - try GetBoundingBox if available
          # Create VARIANT objects for output parameters
          minpoint = WIN32OLE_VARIANT.new([0.0, 0.0, 0.0], WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)
          maxpoint = WIN32OLE_VARIANT.new([0.0, 0.0, 0.0], WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_R8)
          
          # Get the bounding box coordinates
          ole_obj.GetBoundingBox(minpoint, maxpoint)
          
          # Convert the VARIANT arrays to Point3d objects
          min_pt = Point3d.new(minpoint.value[0], minpoint.value[1], minpoint.value[2])
          max_pt = Point3d.new(maxpoint.value[0], maxpoint.value[1], maxpoint.value[2])
          
          BoundingBox.from_min_max(min_pt, max_pt)
        else
          # If we can't determine bounds, create a default bounding box
          # This is better than raising an error in many cases
          BoundingBox.empty
        end
      rescue => e
        # If all methods fail, return an empty bounding box instead of raising an error
        # This makes the code more robust when dealing with various object types
        BoundingBox.empty
      end
    end

    
    #
    #
    #
    #
    # @rbs return bool -- true if ole type is Text
    # def text?
    def text?
      ole_obj.ole_type == "IAcadText"
    end

    # @rbs return bool -- true if ole type is TextNode
    def mtext?
      ole_obj.ole_type == "IAcadMText"
    end

    def has_tags?
      ole_obj.HasAnyTags
    end

    def to_ole
      ole_obj
    end

    # @rbs return bool -- true if object is of type cell
    def cell?
      ole_obj.Type == ::ACAD::MsdElementTypeCellHeader
    end

    # def complex
    #   ole_obj.IsComplexElement
    # end

    # @rbs return bool -- true if Text or TextNode
    def textual?
      text? || mtext?
    end

    def autocad_id
      @ole_obj.ObjectId
    end

    def visible?
      @ole_obj.Visible
    end

    # @rbs return bool -- true if ole type is TypeLine
    def line?
      ole_obj.ObjectName == "AcdbLine"
    end

    def graphical?
      ole_obj.IsGraphical
    end

    def inspect
      "<#{self.class}: #{autocad_id}>"
    end

    def parent
      parent_id = ole_obj.ParentID
      return nil unless parent_id

      id = id_from_record(parent_id)
      app.active_design_file.find_by_id(id)
    end

    def id_from_record(id)
      return unless id.instance_of?(WIN32OLE_RECORD)
      return id.Low if id.Low > id.High

      id.High
    end

    def select
      app.active_model_reference.select_element(self)
    end

    # def Type
    #   ole_obj.Type
    # end

    def autocad_type
      ole_obj.ObjectName
    end

    def model
      Model.new(app, app.current_drawing, ole_obj.ModelReference)
    end
  end

  class Element
    include ElementTrait

    def self.convert_item(ole, app, cell = nil)
      return Point3d.from_ole(ole) if ole.instance_of?(WIN32OLE_RECORD) && ole.typename == "Point3d"
      return ole unless ole.instance_of?(WIN32OLE)

      if ole.respond_to? :ObjectName
        typ = case ole.ObjectName
        when "AcDbModelSpace"
          ::Autocad::ModelSpace.new(ole, app, typ)
        when "AcDbPaperSpace"
          ::Autocad::PaperSpace.new(ole, app, typ)
        when "AcDbBlockTableRecord"
          ::Autocad::Block.new(ole, app, typ, cell)
        when "AcDbPolyline"
          ::Autocad::Polyline.new(ole, app, typ, cell)
        when "AcDbText"
          ::Autocad::Text.new(ole, app, typ, cell)
        when "AcDbMText"
          ::Autocad::TextNode.new(ole, app, typ, cell)
        when "AcDbArc"
          ::Autocad::Arc.new(ole, app, typ, cell)
        when "AcDbViewport"
          ::Autocad::Viewport.new(ole, app, typ)
        when "AcDbBlock"
          ::Autocad::Block.new(ole, app, typ)
        when "AcDbLayerTableRecord"
          ::Autocad::Layer.new(ole, app, typ)
        when AcDbLayerTableRecord
        end

        return typ if typ
        binding.irb

      else
        typ = ole.ole_type
        result = case typ.name
        when "IAcadSelectionSet"
          drawing = app.current_drawing
          ::Autocad::SelectionSetAdapter.from_ole_obj(drawing, ole)
        when "IAcadLayer"
          ::Autocad::Layer.new(ole, app, typ)
        when "IAcadLine"
          ::Autocad::Line.new(ole, app, typ)
        when "IAcadCircle"
          ::Autocad::Circle.new(ole, app, typ)
        when "IAcadLWPolyline"
          ::Autocad::Polyline.new(ole, app, typ)
        when "IAcadLineType"
          ::Autocad::Linetype.new(ole, app, typ)
        when "IAcadText"
          ::Autocad::Text.new(ole, app, typ)
        when "IAcadModelSpace"
          ::Autocad::ModelSpace.new(ole, app, typ)
        when "IAcadPaperSpace"
          ::Autocad::PaperSpace.new(ole, app, typ)
        when "IAcadMText"
          ::Autocad::MText.new(ole, app, typ)
        when "IAcadPViewport"
          ::Autocad::PViewport.new(ole, app, typ)
        when "IAcadBlockReference"
          ::Autocad::BlockReference.new(ole, app, typ)
        when "IAcadExternalReference"
          ::Autocad::ExternalReference.new(ole, app, typ)
        when "IAcadAttributeReference"
          ::Autocad::AttributeReference.new(ole, app, typ)
        when "IAcadLayout"
          ::Autocad::Layout.new(ole, app, typ)
        when "IAcadPlotConfiguration"
          ::Autocad::PlotConfiguration.new(ole, app, typ)

        when "IAcadPlot"
          ::Autocad::Plot.new(ole, app, typ)
        when "IAcadSpline"
          ::Autocad::Spline.new(ole,app,typ)
        else
          binding.irb
          Element.new(ole, app, typ)
        end

        return result if result
        binding.irb
      end
    end

    def self.ole_object?
      ole.instance_of?(WIN32OLE)
    end

    attr_reader :ole_obj, :app, :acad_type, :original

    def initialize(ole, app, typ, cell = nil)
      @ole_obj = ole
      @original = read_ole(ole)
      @app = app
      @cell = cell
      @acad_type = typ
    end

    def in_cell?
      !!@cell
    end

    def read_ole(ole)
    end

    def write_ole(value)
    end

    def method_missing(meth, *, &)
      if /^[A-Z]/.match?(meth.to_s)
        result = ole_obj.send(meth, *, &)
        Element.convert_item(result, app)
      else
        super
      end
    end

    def get_property_handler
      ph_ole = app_ole_obj.CreatePropertyHandler(ole_obj)
      PropertyHandler.new(ph_ole)
    end

    def property_handler
      @property_handler ||= get_property_handler
    end

    def [](name)
      property_handler[name]
    end

    def do_update(value)
      return false if value == original

      saved_original = original
      begin
        write_ole(value)
        @original = read_ole(ole_obj)
        true
      rescue
        @original = saved_original
        false
      end
    end

    def update(value)
      redraw_el = ole_obj
      if do_update(value)
        if in_cell?
          @cell.ReplaceCurrentElement @ole_obj
          redraw_el = @cell
        end
        redraw(redraw_el)
        @updated = true
        true
      else
        @updated = false
        false
      end
    rescue => e
      app.error_proc.call(e, nil)
    end

    def updated?
      @updated
    end

    def redraw(el = ole_obj)
      # el.Redraw ::Autocad::MSD::MsdDrawingModeNormal if el.IsGraphical
      el.Update
    rescue
      nil
    end

    def app_ole_obj
      app.ole_obj
    end

    def delete
      ole_obj.Delete
    rescue => ex
      raise Autocad::Error.new("Error deleting object #{self} #{ex}")
    end

    def clone(new_insertion_point)
      pt = Point3d.new(new_insertion_point)
      ole = ole_obj.Copy(pt.to_ole)
      app.wrap(ole)
    rescue => ex
      raise Autocad::Error.new("Error cloning object #{ex}")
    end

    def move_x(amt)
      pt1 = Point3d(0, 0, 0)
      pt2 = Point3d(amt, 0, 0)
      move_ole(pt1.to_ole, pt2.to_ole)
    end

    def move_y(amt)
      pt1 = Point3d(0, 0, 0)
      pt2 = Point3d(0, 1, 0)
      move_ole(pt1.to_ole, pt2.to_ole)
    end

    def move(x, y)
      pt1 = Point3d(0, 0, 0)
      pt2 = Point3d(x, y, 0)
      move_ole(pt1.to_ole, pt2.to_ole)
    end

    def move_ole(pt1, pt2)
      ole_obj.Move(pt1, pt2)
      app.wrap(ole_obj)
    rescue => ex
      raise Autocad::Error.new("Error moving object #{ex}")
    end

    def ole_cell(ole)
      ole.IsCellElement || ole.IsSharedCellElement
    end

    # def each_cell(ole, &)
    #   cell = ole if ole_cell(ole)
    #   begin
    #     ole.ResetElementEnumeration
    #   rescue
    #     binding.break
    #   end
    #   while ole.MoveToNextElement
    #     component = ole.CopyCurrentElement
    #     if component.IsTextNodeElement
    #       yield Autocad::Wrap.wrap(component.AsTextNodeElement, app, cell)
    #     elsif component.IsTextElement
    #       yield Autocad::Wrap.wrap(component.AsTextElement, app, cell)
    #     elsif component.IsComplexElement
    #       each(component, &)
    #     else
    #       yield Autocad::Wrap.wrap(component, app, cell)
    #     end
    #   end
    # end

    # def each(ole = ole_obj, &block)
    #   return unless ole.IsComplexElement
    #   return to_enum(:each) unless block

    #   if ole.IsCellElement
    #     each_cell(ole, &block)
    #   else
    #     each_complex(ole, &block)
    #   end
    # end

    def each_complex(ole, &)
      cell = nil
      components = ole.GetSubElements
      while components.MoveNext
        component = components.Current
        if component.IsTextNodeElement
          yield Autocad::Wrap.wrap(component.AsTextNodeElement, app, cell)
        elsif component.IsTextElement
          yield Autocad::Wrap.wrap(component.AsTextElement, app, cell)
        elsif component.IsComplexElement
          each(component, &)
        else
          yield Autocad::Wrap.wrap(component, app, cell)
        end
      end
    end
  end

  class App
    def ole_to_ruby(ole)
      Element.convert_item(ole, self)
    end
  end
end

module Autocad
  class Arc < Element
  end
end

module Autocad
  class Ellipse < Element
  end
end

module Autocad
  class BSplineSurface < Element
  end
end

module Autocad
  class Linetype < Element
    CONTINUOUS = "Continuous"
    DASHED = "Dashed"
    CENTER = "Center"
    HIDDEN = "Hidden"
    PHANTOM = "Phantom"
    BREAK = "Break"
    BORDER = "Border"
    DOT2 = "Dot2"
    DOTX2 = "DotX2"
    DIVIDE = "Divide"
    TRACKING = "Tracking"
    DASHDOT = "Daskdot"

    def name
      ole_obj.Name
    end
  end
end

module Autocad
  class BSplineCurve < Element
  end
end
