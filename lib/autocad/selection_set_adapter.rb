module Autocad
  class SelectionSetAdapter
    def initialize(drawing, selection_set)
      @drawing = drawing
      @selection_set = selection_set
    end

    def select_on_screen
      types = create_ole_variant(@selection_set.to_ole_filter_type)
      values = create_ole_variant(@selection_set.to_ole_filter_value)
      
      ole_selection_set = @drawing.ole_obj.SelectionSets.Add(@selection_set.name)
      ole_selection_set.SelectOnScreen(types, values)
    end

    private

    def create_ole_variant(data)
      return nil unless data
      
      if data.first.is_a?(Integer)
        WIN32OLE::VARIANT.new(data, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_I2)
      else
        WIN32OLE::VARIANT.new(data, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_VARIANT)
      end
    end
  end
end
