require_relative "element"

module Autocad
  class Block < Element
    def each
      return enum_for(:each) unless block_given?
      @ole_obj.each do |ole|
        yield app.wrap(ole)
      end
    end

    def has_attributes?
      @ole_obj.HasAttributes
    end

    def name
      @ole_obj.Name
    end

    def layout?
      @ole_obj.IsLayout
    end

    def xref?
      @ole_obj.IsXRef
    end

    def dynamic?
      @ole_obj.IsDynamicBlock
    end

    def attribute_hash
      attributes.each.with_object({}) do |a, h|
        h[a.key] = a.value
      end
    end

    def block_type
      if xref?
        "XRef"
      elsif dynamic?
        "Dynamic"
      elsif layout?
        "Layout"
      end
    end

    def inspect
      "<Block #{block_type}: '#{name}#' #{autocad_id}>"
    end

    def attributes
      els = @ole_obj.GetAttributes
      return [] if els.empty?
      Attributes.new(self, els.map { |e| Attribute.new(e, app) })
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
      if att = find_attribute(name)
        att.update(value)
      end
    end

    def each
      return to_enum(:each) unless block_given?
      elements.each do |el|
        yield el
      end
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

  class Attribute < Element
    def write_ole(value)
      @ole_obj.TextString = value
    end

    def read_ole(value)
      @ole_obj.TextString
    end

    def key
      @ole_obj.TagString
    end

    def value
      @ole_obj.TextString
    end

    def inspect
      "<Attribute #{key}: #{value}>"
    end
  end
end
