module Autocad
  # Builds AutoCAD selection filter criteria using group codes
  #
  # Provides a fluent interface for creating complex entity filters
  # based on AutoCAD DXF group codes and logical operations.
  #
  # Key Features:
  # - Logical operators (AND, OR, NOT, XOR)
  # - Comparison operators (>, <, =, !=)
  # - Entity property filters (type, layer, color)
  # - Text content matching
  # - Space-specific filtering (model/paper)
  #
  # @example Create a filter for red circles
  #   filter = SelectionFilter.new
  #     .and(
  #       SelectionFilter.new.type("CIRCLE"),
  #       SelectionFilter.new.color(1)
  #     )
  #
  # @example Complex filter with nested conditions
  #   filter = SelectionFilter.new
  #     .and(
  #       SelectionFilter.new.layer("WALLS"),
  #       SelectionFilter.new.or(
  #         SelectionFilter.new.type("LINE"),
  #         SelectionFilter.new.type("POLYLINE")
  #       )
  #     )
  class SelectionFilter
    # @rbs attr_reader types: Array[Integer] -- AutoCAD group codes (e.g., 0=Entity type)
    # @rbs attr_reader values: Array[untyped] -- Filter values matching group codes
    attr_reader :types, :values

    # Initialize empty filter
    # @return [void]
    # @rbs return void
    def initialize
      @types = []
      @values = []
    end

    # Check if filter has any conditions
    # @return [Boolean] True if filter has conditions
    # @example Skip empty filter
    #   next unless filter.has_filters?
    # @rbs return bool
    def has_filters?
      @types.any?
    end

    # Logical AND combination of filters
    # @param conditions [Array<SelectionFilter>] Filters to combine
    # @return [self] The filter for chaining
    # @example Combine multiple conditions with AND
    #   filter.and(
    #     SelectionFilter.new.type("LINE"),
    #     SelectionFilter.new.layer("WALLS")
    #   )
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
    # @param conditions [Array<SelectionFilter>] Filters to combine
    # @return [self] The filter for chaining
    # @example Match entities on multiple layers
    #   filter.or(
    #     SelectionFilter.new.layer("WALLS"),
    #     SelectionFilter.new.layer("DOORS")
    #   )
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
    # @param condition1 [SelectionFilter] First filter
    # @param condition2 [SelectionFilter] Second filter
    # @return [self] The filter for chaining
    # @example Select entities that match exactly one condition
    #   filter.xor(
    #     SelectionFilter.new.type("CIRCLE"),
    #     SelectionFilter.new.layer("SPECIAL")
    #   )
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
    # @param condition [SelectionFilter] Filter to negate
    # @return [self] The filter for chaining
    # @example Select everything except circles
    #   filter.not(SelectionFilter.new.type("CIRCLE"))
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

    # Greater than comparison
    # @param value [Numeric] Comparison value
    # @return [self] The filter for chaining
    # @example Find circles with radius > 5
    #   filter.type("CIRCLE").greater_than(5)
    # @rbs value: Numeric -- Comparison value
    # @rbs return SelectionFilter
    def greater_than(value)
      @types << -4
      @values << ">="
      @types << 40 # floating point
      @values << value
      self
    end

    # Less than comparison
    # @param value [Numeric] Comparison value
    # @return [self] The filter for chaining
    # @example Find circles with radius < 10
    #   filter.type("CIRCLE").less_than(10)
    # @rbs value: Numeric -- Comparison value
    # @rbs return SelectionFilter
    def less_than(value)
      @types << -4
      @values << "<="
      @types << 40 # floating point
      @values << value
      self
    end

    # Equal to comparison
    # @param value [Numeric] Comparison value
    # @return [self] The filter for chaining
    # @example Find circles with radius = 7.5
    #   filter.type("CIRCLE").equal_to(7.5)
    # @rbs value: Numeric -- Comparison value
    # @rbs return SelectionFilter
    def equal_to(value)
      @types << -4
      @values << "="
      @types << 40 # floating point
      @values << value
      self
    end

    # Not equal to comparison
    # @param value [Numeric] Comparison value
    # @return [self] The filter for chaining
    # @example Find circles with radius != 5
    #   filter.type("CIRCLE").not_equal_to(5)
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
    # @param name [String, nil] Optional block name pattern
    # @return [self] The filter for chaining
    # @example Find any block reference
    #   filter.block_reference
    # @example Find specific block
    #   filter.block_reference("DOOR")
    # @rbs name: String? -- Optional block name pattern
    # @rbs return SelectionFilter
    def block_reference(name = nil)
      # return unless name

      @types << 0
      @values << "INSERT"
      self
    end

    # Filter by entity name/type
    # @param value [String] Entity type name (e.g., "CIRCLE")
    # @return [self] The filter for chaining
    # @example Filter by entity name
    #   filter.name("CIRCLE")
    # @rbs value: String -- Entity type name (e.g., "CIRCLE")
    # @rbs return SelectionFilter
    def name(value)
      @types << [0, 2]
      @values << value
      self
    end

    # Filter by entity type
    # @param kind [String] Entity type name (e.g., "CIRCLE")
    # @return [self] The filter for chaining
    # @example Filter for lines
    #   filter.type("LINE")
    # @rbs kind: String -- Entity type name (e.g., "CIRCLE")
    # @rbs return SelectionFilter
    def type(kind)
      @types << 0
      @values << kind
      self
    end

    # Filter by layer name
    # @param name [String] Layer name
    # @return [self] The filter for chaining
    # @example Filter for entities on a specific layer
    #   filter.layer("WALLS")
    # @rbs name: String -- Layer name
    # @rbs return SelectionFilter
    def layer(name)
      @types << 8
      @values << name
      self
    end

    # Filter by visibility state
    # @param vis [Boolean] True for visible entities
    # @return [self] The filter for chaining
    # @example Filter for visible entities
    #   filter.visible(true)
    # @example Filter for hidden entities
    #   filter.visible(false)
    # @rbs vis: bool -- True for visible entities
    # @rbs return SelectionFilter
    def visible(vis = true)
      @types << 60
      @values << (vis ? 0 : 1)
      self
    end

    # Filter by color index
    # @param num [Integer] AutoCAD color number (0-256)
    # @return [self] The filter for chaining
    # @example Filter for red entities (color 1)
    #   filter.color(1)
    # @rbs num: Integer -- AutoCAD color number (0-256)
    # @rbs return SelectionFilter
    def color(num)
      @types << 62 # Color number filter
      @values << num
      self
    end

    # Filter for paper space entities
    # @return [self] The filter for chaining
    # @example Filter for paper space entities
    #   filter.paper_space
    # @rbs return SelectionFilter
    def paper_space
      @types << 67  # Paper space filter
      @values << 1
      self
    end

    # Filter for model space entities
    # @return [self] The filter for chaining
    # @example Filter for model space entities
    #   filter.model_space
    # @rbs return SelectionFilter
    def model_space
      @types << 67  # Model space filter
      @values << 0
      self
    end

    # Filter text content using wildcards
    # @param str [String] Search pattern (e.g., "*REV*")
    # @return [self] The filter for chaining
    # @example Find text containing "REVISION"
    #   filter.contains("*REVISION*")
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

    # Helper method for text content matching
    # @param str [String] Text to search for
    # @return [self] The filter for chaining
    # @example Find text containing specific content
    #   filter.has_text("Revision")
    # @rbs str: String -- Text to search for
    # @rbs return SelectionFilter
    def has_text(str)
      contains(str)
    end
  end
end
