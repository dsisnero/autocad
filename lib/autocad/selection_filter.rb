module Autocad
  # Builds AutoCAD selection filter criteria using group codes
  class SelectionFilter
    # @rbs attr_reader types: Array[Integer] -- AutoCAD group codes (e.g., 0=Entity type)
    # @rbs attr_reader values: Array[untyped] -- Filter values matching group codes
    attr_reader :types, :values

    # Initialize empty filter
    # @rbs return void
    def initialize
      @types = []
      @values = []
    end

    # Check if filter has any conditions
    # @rbs return bool
    def has_filters?
      @types.any?
    end

    # Logical AND combination of filters
    # @rbs *conditions: Array[SelectionFilter] -- Filters to combine
    # @rbs return SelectionFilter
    def and(*conditions)
      return self if conditions.empty?

      @types << -4
      @values << "<AND"

      conditions.each do |condition|
        @types.concat(condition.types)
        @values.concat(condition.values)
      end

      @types << -4
      @values << "AND>"

      self
    end

    # Logical OR combination of filters
    # @rbs *conditions: Array[SelectionFilter]
    # @rbs return SelectionFilter
    def or(*conditions)
      return self if conditions.empty?

      @types << -4
      @values << "<OR"

      conditions.each do |condition|
        @types.concat(condition.types)
        @values.concat(condition.values)
      end

      @types << -4
      @values << "OR>"

      self
    end

    # Logical XOR combination of two filters
    # @rbs condition1: SelectionFilter
    # @rbs condition2: SelectionFilter
    # @rbs return SelectionFilter
    def xor(condition1, condition2)
      @types << -4
      @values << "<XOR"

      @types.concat(condition1.types)
      @values.concat(condition1.values)

      @types.concat(condition2.types)
      @values.concat(condition2.values)

      @types << -4
      @values << "XOR>"

      self
    end

    # Logical NOT for a filter condition
    # @rbs condition: SelectionFilter
    # @rbs return SelectionFilter
    def not(condition)
      @types << -4
      @values << "<NOT"

      @types.concat(condition.types)
      @values.concat(condition.values)

      @types << -4
      @values << "NOT>"

      self
    end

    # Relational Operators
    #  f.type("Circle").greater_than(5)
    # @rbs value: Numeric -- Comparison value
    # @rbs return SelectionFilter
    def greater_than(value)
      @types << -4
      @values << ">="
      @types << 40 # floating point
      @values << value
      self
    end

    # @rbs value: Numeric -- Comparison value
    # @rbs return SelectionFilter
    def less_than(value)
      @types << -4
      @values << "<="
      @types << 40 # floating point
      @values << value
      self
    end

    # @rbs value: Numeric -- Comparison value
    # @rbs return SelectionFilter
    def equal_to(value)
      @types << -4
      @values << "="
      @types << 40 # floating point
      @values << value
      self
    end

    # @rbs value: Numeric -- Comparison value
    # @rbs return SelectionFilter
    def not_equal_to(value)
      @types << -4
      @values << "<>"
      @types << 40 # floating point
      @values << value
      self
    end

    # Filter by block references
    # @rbs name: String? -- Optional block name pattern
    # @rbs return SelectionFilter
    def block_reference(name = nil)
      # return unless name

      @types << 0
      @values << "INSERT"
      self
    end

    # Filter by entity name/type
    # @rbs value: String -- Entity type name (e.g., "CIRCLE")
    # @rbs return SelectionFilter
    def name(value)
      @types << [0, 2]
      @values << value
      self
    end

    # Filter by entity type
    # @rbs kind: String -- Entity type name (e.g., "CIRCLE")
    # @rbs return SelectionFilter
    def type(kind)
      @types << 0
      @values << kind
      self
    end

    # Filter by layer name
    # @rbs name: String -- Layer name
    # @rbs return SelectionFilter
    def layer(name)
      @types << 8
      @values << name
      self
    end

    # Filter by visibility state
    # @rbs vis: bool -- True for visible entities
    # @rbs return SelectionFilter
    def visible(vis = true)
      @types << 60
      @values << (vis ? 0 : 1)
      self
    end

    # Filter by color index
    # @rbs num: Integer -- AutoCAD color number (0-256)
    # @rbs return SelectionFilter
    def color(num)
      @types << 62 # Color number filter
      @values << num
      self
    end

    # Filter by workspace type
    # @rbs return SelectionFilter
    def paper_space
      @types << 67  # Paper space filter
      @values << 1
      self
    end

    # @rbs return SelectionFilter
    def model_space
      @types << 67  # Model space filter
      @values << 0
      self
    end

    # Filter text content using wildcards
    # @rbs str: String -- Search pattern (e.g., "*REV*")
    # @rbs return SelectionFilter
    def contains(str)
      @types << -4
      @values << "<OR"

      # Filter for TEXT
      @types << 1 # Text string group code for TEXT
      @values << "*#{str}*"

      # Filter for MTEXT
      @types << 1 # Text string group code for MTEXT
      @values << "*#{str}*"

      @types << -4
      @values << "OR>"

      self
    end
  end
end
