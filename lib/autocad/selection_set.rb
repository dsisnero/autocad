module Autocad
  class SelectionSet < Element
    attr_reader :filter_types, :filter_values

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

    def filter_text(str = nil)
      filter do |f|
        text_filter = f.or(
          f.type('TEXT'),
          f.type('MTEXT')
        )

        if str
          text_filter = f.and(
            text_filter,
            f.contains(str)
          )
        end

        text_filter
      end
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
      ole_obj.SelectOnScreen(ole_filter_types, ole_filter_values)
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
      self
    end
  end

  class SelectionFilter
    def initialize
      @filter_types = []
      @filter_values = []
    end

    def has_filters?
      @filter_types.size > 0
    end

    # Logical Operators
    def and(*conditions)
      @filter_types << -4
      @filter_values << '<AND'

      conditions.each do |condition|
        @filter_types.concat(condition.types)
        @filter_values.concat(condition.values)
      end

      @filter_types << -4
      @filter_values << 'AND>'

      self
    end

    def or(*conditions)
      @filter_types << -4
      @filter_values << '<OR'
      self.class.new

      conditions.each do |condition|
        @filter_types.concat(condition.types)
        @filter_values.concat(condition.values)
      end

      @filter_types << -4
      @filter_values << 'OR>'

      self
    end

    def xor(condition1, condition2)
      @filter_types << -4
      @filter_values << '<XOR'

      @filter_types.concat(condition1.types)
      @filter_values.concat(condition1.values)

      @filter_types.concat(condition2.types)
      @filter_values.concat(condition2.values)

      @filter_types << -4
      @filter_values << 'XOR>'

      self
    end

    def not(condition)
      @filter_types << -4
      @filter_values << '<NOT'

      @filter_types.concat(condition.types)
      @filter_values.concat(condition.values)

      @filter_types << -4
      @filter_values << 'NOT>'

      self
    end

    # Relational Operators
    #  f.type("Circle").greater_than(5)
    def greater_than(value)
      @filter_types << -4
      @filter_values << '>='
      @filter_types << 40 # floating point
      @filter_values << value
      self
    end

    def less_than(value)
      @filter_types << -4
      @filter_values << '<='
      @filter_types << 40 # floating point
      @filter_values << value
      self
    end

    def equal_to(value)
      @filter_types << -4
      @filter_values << '='
      @filter_types << 40 # floating point
      @filter_values << value
      self
    end

    def not_equal_to(value)
      @filter_types << -4
      @filter_values << '<>'
      @filter_types << 40 # floating point
      @filter_values << value
      self
    end

    def block_reference(name = nil)
      # return unless name

      @filter_types << 0
      @filter_values << 'INSERT'
      self
    end

    def name(value)
      @filter_types << [0, 2]
      @filter_values << value
      self
    end

    def type(kind)
      @filter_types << 0
      @filter_values << kind
      self
    end

    def layer(name)
      @filter_types << 8
      @filter_values << name
      self
    end

    def visible(vis = true)
      @filter_types << 60
      @filter_values << (vis ? 0 : 1)
      self
    end

    def color(num)
      @filter_types << 62 # Color number filter
      @filter_values << num
      self
    end

    def paper_space
      @filter_types << 67  # Paper space filter
      @filter_values << 1
      self
    end

    def model_space
      @filter_types << 67  # Model space filter
      @filter_values << 0
      self
    end

    def contains(str)
      @filter_types << -4
      @filter_values << '<OR'

      # Filter for TEXT
      @filter_types << 1 # Text string group code for TEXT
      @filter_values << "*#{str}*"

      # Filter for MTEXT
      @filter_types << 1 # Text string group code for MTEXT
      @filter_values << "*#{str}*"

      @filter_types << -4
      @filter_values << 'OR>'

      self
    end

    def types
      @filter_types
    end

    def values
      @filter_values
    end
  end
end
