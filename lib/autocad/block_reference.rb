require_relative "element"

module Autocad


  class BlockReference < Element
    def each
      return enum_for(:each) unless block_given?

      @ole_obj.each do |ole|
        yield app.wrap(ole)
      end
    end

    def external?
      false
    end

    def insertion_point
      Point3d(ole_obj.InsertionPoint)
    rescue
      Autocad::Error.new("error getting insertion point of block #{name}")
    end

    def dynamic?
      @ole_obj.IsDynamicBlock
    end

    def has_attributes?
      @ole_obj.HasAttributes
    end

    def name
      @ole_obj.Name
    end

    def x_scale_factor
      @ole_obj.XScaleFactor
    end

    def x_effective_scale_factor
      @ole_obj.XEffectiveScaleFactor
    end

    def y_scale_factor
      @ole_obj.YScaleFactor
    end

    def y_effective_scale_factor
      @ole_obj.YEffectiveScaleFactor
    end

    def z_scale_factor
      @ole_obj.ZScaleFactor
    end

    def z_effective_scale_factor
      @ole_obj.ZEffectiveScaleFactor
    end

    def layout?
      @ole_obj.IsLayout
    end

    def attribute_hash
      attributes.each.with_object({}) do |a, h|
        h[a.key] = a.value
      end
    end

    def inspect
      "<BlockReference: #{autocad_id}>"
    end

    def attributes
      return to_enum(__callee__) unless block_given?
      els = @ole_obj.GetAttributes
      return [] if els.empty?
      els.each { |e| yield app.wrap(e) }
    end
  end

  class ExternalReference < BlockReference

    def external?
      true
    end


    def ins_units
       @ole_obj.InsUnits
    end

    def ins_units_factor
      @ole_obj.InsUnitsFactor
    end

    def inspect
      "<ExternalReference: #{autocad_id}>"
    end

  end

  class Attributes
    include Enumerable
    attr_reader :elements

    def initialize(blk, elements)
      @block = blk
      @elements = elements
    end

    def update_element(name, value)
      return unless att = find_attribute(name)

      att.update(value)
    end

    def each(&block)
      return to_enum(:each) unless block_given?

      elements.each(&block)
    end

    def find_attribute(name)
      elements.find { |a| a.key == name }
    end

    def [](name)
      el = find_attribute(name)
      el.value if el
    end

    def []=(name, value)
      update_element(name, value)
    end

    def keys
      @elements.map { |e| e.key }
    end

    def values
      @elements.map { |e| e.value }
    end

    def to_h
      result = {}
      elements.each.with_object(result) do |a, h|
        h[a.key] = a.value
      end
      result
    end

    def inspect
      "<Attributes count#{elements.size}>"
    end
  end

  class AttributeReference < Element

    # @rbs return bool -- is the text multiline
    def mtext?
      ole_obj.MTextAttribute
    end
    def write_ole(value)
      if mtext?
        @ole_obj.MTextAttributeContent = value
      else
        @ole_obj.TextString = value
      end
    end

    def read_ole(value)
      if mtext?
        @ole_obj.MTextAttributeContent
      else
      @ole_obj.TextString
      end
    end

    def key
      @ole_obj.TagString
    end

    def value
    if mtext?
      @ole_obj.MTextAttributeContent
    else
      @ole_obj.TextString
    end
    end

    def inspect
      "<Attribute #{key}: #{value}>"
    end
  end
end
