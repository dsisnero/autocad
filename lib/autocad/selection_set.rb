module Autocad
  class SelectionSet < Element
    attr_reader :name, :filter_types, :filter_values

    def initialize(...)
      super
      @filter_types = nil
      @filter_values = nil
    end

    def slset_cond(filter_type, filter_data)
      ft = WIN32OLE::Varient.array([2], WIN32OLE::VARIANT::VT_I2)
      ft[0] = filter_type[0]
      ft[1] = filter_type[1]
      fd = WIN32OLE::Varient.array([2], WIN32OLE::VARIANT::VT_VARIANT)
      fd[0] = filter_data[0]
      fd[1] = filter_data[1]
    end

    def name
      ole_obj.Name
    end

    def ole_filter_type
      return nil unless filter_types
      return nil unless filter_types.size > 0

      WIN32OLE::Varient.new(filter_types, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_I2)
    end

    def ole_filter_values
      return nil unless filter_types
      return nil unless filter_types.size > 0

      WIN32OLE::Variant.new(filter_values, WIN32OLE::VARIANT::VT_ARRAY | WIN32OLE::VARIANT::VT_VARIANT)
    end

    def select_on_screen
      ole_obj.SelectOnScreen(filter_types, filter_values)
    end

    # filter do |f|
    #   st = f.type('Circle').or(f.type('Arc'))
    #   st2 = f.layer('0').or(f.layer('1'))
    #   f.and(st, st2)
    # end
    #
    def filter
      filter = SelectionFilter.new
      new_filter = yield filter
      return unless new_filter.has_filters?

      @filter_types = new_filter.types.flatten
      @filter_values = new_filter.values.flatten
    end
  end

  class SelectionFilter
    def has_filters?
    end

    def and(type, value)
    end

    def block_reference
    end

    def name(value)
    end

    def type(kind)
    end

    def layer(name)
    end

    def visible(vis)
    end

    def color(num)
    end

    def paper_space
    end

    def model_space
    end

    def not(op)
    end

    def or(aft)
    end
  end
end
