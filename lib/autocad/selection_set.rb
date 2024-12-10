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

    def filter_text
      filter do |f|
        f.type('TEXT')
        f.or(f.type('MTEXT'))
      end
    end

    def ole_filter_type
      return nil unless filter_types
      return nil unless filter_types.size > 0

      WIN32OLE::Varient.new(filter_types)
    end

    def ole_filter_values
      return nil unless filter_types
      return nil unless filter_types.size > 0

      WIN32OLE::Variant.new(filter_values)
    end

    def select_on_screen
      ole_obj.SelectOnScreen(filter_types, filter_values)
    end

    def filter
      filter = SelectionFilter.new
      new_filter = yield filter
      return unless new_filter.has_filters?

      @filter_types = new_filter.types.flatten
      @filter_values = new_filter.values.flatten
    end
  end

  class SelectionFilter
    attr_reader :types, :values

    def initialize
      @types = []
      @values = []
    end

    def has_filters?
      @types.size > 0
    end

    def and(type, value)
    end

    def block_reference
      @types << 0
      @values << 'INSERT'
      self
    end

    def name(value)
      types << 2
      values << value
      self
    end

    def type(kind)
      types << 0
      values << kind
      self
    end

    def layer(name)
      types << 8
      values << name
      self
    end

    def visible(vis)
      case vis
      when true
        types << 60
        values << 0
      else
        types << 60
        values << 1
      end
      self
    end

    def color(num)
      types << 62
      values << num
      self
    end

    def paper_space
      types << 67
      values << 1
      self
    end

    def model_space
      types << 67
      values << 0
      self
    end

    def not(op)
      t1 = op.types.flatten.dup
      t2 = op.values.flatten.dup
      binding.irb
      types << -4 << t1
      values << '<NOT' << t2
      types << -4
      values << 'NOT>'
      self
    end

    def or(aft)
      t1 = types.dup
      v1 = values.dup
      @types = []
      @values = []
      types << -4
      values << '<OR'
      types << t1
      values << v1
      types << aft.types
      types << aft.values
      types << -4
      values << 'OR>'
      self
    end
  end
end
