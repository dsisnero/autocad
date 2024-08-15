# require "autocad/property_handler"

class WIN32OLE
  def to_ole
    self
  end
end

module Autocad
end

module Autocad
  module ElementTrait
    #
    #
    #
    # @return [Boolean] true if ole type is Text
    #
    def text?
      ole_obj.Type == ::ACAD::MsdElementTypeText
    end

    # @return [Boolean] true if ole type is TextNode
    def text_node?
      ole_obj.Type == ::ACAD::MsdElementTypeTextNode
    end

    def has_tags?
      ole_obj.HasAnyTags
    end

    def to_ole
      ole_obj
    end

    def cell?
      ole_obj.Type == ::ACAD::MsdElementTypeCellHeader
    end

    def complex?
      ole_obj.IsComplexElement
    end

    # @return [Boolean] true if Text or TextNode
    def textual?
      text? || text_node?
    end

    def autocad_id
      @ole_obj.ObjectId
    end

    # @return [Boolean] true if ole type is TypeLine
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
      ole_obj.Type
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

      case ole.ObjectName
      when "AcDbModelSpace"
        ::Autocad::ModelSpace.new(ole, app)
      when "AcDbPaperSpace"
        ::Autocad::PaperSpace.new(ole, app)
      when "AcDbBlockTableRecord"
        ::Autocad::Block.new(ole, app, cell)
      when "AcDbLine"
        ::Autocad::Line.new(ole, app, cell)
      when "AcDbPolyline"
        ::Autocad::Polyline.new(ole, app, cell)
      when "AcDbText"
        ::Autocad::Text.new(ole, app, cell)
      when "AcDbMText"
        ::Autocad::TextNode.new(ole, app, cell)
      when "AcDbArc"
        ::Autocad::Arc.new(ole, app, cell)
      when "AcDbViewport"
        ::Autocad::Viewport.new(ole, app)
      when "AcDbBlock"
        ::Autocad::Block.new(ole, app)
      when "AcDbBlockReference"
        ::Autocad::BlockReference.new(ole, app)
      else

        require "debug"
        binding.break

        new(ole, app, cell)
      end
    end

    def self.ole_object?
      ole.instance_of?(WIN32OLE)
    end

    attr_reader :ole_obj, :app, :original

    def initialize(ole, app, cell = nil)
      @ole_obj = ole
      @original = read_ole(ole)
      @app = app
      @cell = cell
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
      rescue => e
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
    rescue => e
      app.error_proc.call(e, nil)
    end

    def app_ole_obj
      app.ole_obj
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
  class BSplineCurve < Element
  end
end
