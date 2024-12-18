module Autocad
  class SelectionFilter
    attr_reader :types, :values

    def initialize
      @types = []
      @values = []
    end

    def has_filters?
      @types.any?
    end

    # Logical Operators
    def and(*conditions)
      return self if conditions.empty?
      
      @types << -4
      @values << '<AND'

      conditions.each do |condition|
        @types.concat(condition.types)
        @values.concat(condition.values)
      end

      @types << -4
      @values << 'AND>'

      self
    end

    def or(*conditions)
      return self if conditions.empty?
      
      @types << -4
      @values << '<OR'

      conditions.each do |condition|
        @types.concat(condition.types)
        @values.concat(condition.values)
      end

      @types << -4
      @values << 'OR>'

      self
    end

    def xor(condition1, condition2)
      @types << -4
      @values << '<XOR'

      @types.concat(condition1.types)
      @values.concat(condition1.values)

      @types.concat(condition2.types)
      @values.concat(condition2.values)

      @types << -4
      @values << 'XOR>'

      self
    end

    def not(condition)
      @types << -4
      @values << '<NOT'

      @types.concat(condition.types)
      @values.concat(condition.values)

      @types << -4
      @values << 'NOT>'

      self
    end

    # Relational Operators
    #  f.type("Circle").greater_than(5)
    def greater_than(value)
      @types << -4
      @values << '>='
      @types << 40 # floating point
      @values << value
      self
    end

    def less_than(value)
      @types << -4
      @values << '<='
      @types << 40 # floating point
      @values << value
      self
    end

    def equal_to(value)
      @types << -4
      @values << '='
      @types << 40 # floating point
      @values << value
      self
    end

    def not_equal_to(value)
      @types << -4
      @values << '<>'
      @types << 40 # floating point
      @values << value
      self
    end

    def block_reference(name = nil)
      # return unless name

      @types << 0
      @values << 'INSERT'
      self
    end

    def name(value)
      @types << [0, 2]
      @values << value
      self
    end

    def type(kind)
      @types << 0
      @values << kind
      self
    end

    def layer(name)
      @types << 8
      @values << name
      self
    end

    def visible(vis = true)
      @types << 60
      @values << (vis ? 0 : 1)
      self
    end

    def color(num)
      @types << 62 # Color number filter
      @values << num
      self
    end

    def paper_space
      @types << 67  # Paper space filter
      @values << 1
      self
    end

    def model_space
      @types << 67  # Model space filter
      @values << 0
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

  end
end
