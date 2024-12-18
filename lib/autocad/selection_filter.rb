module Autocad
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
