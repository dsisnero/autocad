# require_relative "selection_filter"
require_relative "filter"

module Autocad
  # Manages named selection criteria for AutoCAD entities
  #
  # Stores filter criteria for entity selection without executing the selection.
  # Works with SelectionSetAdapter to apply filters and retrieve entities.
  #
  # @example Create a selection set with complex filters
  #   ss = SelectionSet.new("walls")
  #   ss.filter do |f|
  #     f.and(f.layer("WALLS"), f.or(f.type("LINE"), f.type("POLYLINE")))
  #   end
  class SelectionSet
    # @rbs attr_reader name: String -- Unique identifier for the selection set
    # @rbs attr_reader filter_types: Array[Integer] -- AutoCAD group codes (DXF codes)
    # @rbs attr_reader filter_values: Array[untyped] -- Filter values matching group codes
    attr_reader :filter_types, :filter_values, :name

    # Initialize a new selection set with a name
    # @param name [String] Unique identifier for the selection set
    # @rbs name: String
    # @rbs return void
    def initialize(name)
      @name = name
      @filter_types = []
      @filter_values = []
    end

    # Check if set has active filters
    # @return [Boolean] True if filters are defined
    # @rbs return bool
    def has_filter?
      filter_types && filter_types.any?
    end

    # Filter for text entities with optional content matching
    # @param str [String, nil] Optional text pattern to match
    # @return [self] The selection set for chaining
    # @example Filter all text entities
    #   ss.filter_text
    # @example Filter text with specific content
    #   ss.filter_text("Revision")
    # @rbs str: String? -- Optional text pattern to match
    # @rbs return self
    def filter_text(str = nil)
      if str
        filter_text_containing(str)
      else
        filter do |f|
          f.or(f.type("TEXT"), f.type("MTEXT"))
        end
      end
    end

    # Configure complex filters through block
    # @yield [Filter] Block for building filter criteria
    # @return [self] The selection set for chaining
    # @example Create a filter for red circles
    #   ss.filter do |f|
    #     f.and(f.type("CIRCLE"), f.color(1))
    #   end
    # @example Combine multiple conditions
    #   ss.filter do |f|
    #     st = f.type('Circle').or(f.type('Arc'))
    #     st2 = f.layer('0').or(f.layer('1'))
    #     f.and(st, st2)
    #   end
    # @rbs &: (Filter) -> Filter
    # @rbs return self
    def filter
      if block_given?
        filter = Filter.new
        result = yield filter
        @filter_types, @filter_values = result.convert_clauses
      end
      self
    end

    # Clear all filter criteria
    # @return [self] The selection set for chaining
    # @rbs return self
    def clear_filter
      @filter_types = []
      @filter_values = []
      self
    end

    # Helper methods for common operations

    # Filter by entity types
    # @param types [Array<String>] Entity type names (e.g., "LINE", "CIRCLE")
    # @return [self] The selection set for chaining
    # @example Filter for lines and polylines
    #   ss.filter_by_type("LINE", "POLYLINE")
    # @rbs *types: Array[String]
    # @rbs return self
    def filter_by_type(*types)
      filter { |f| f.or(*types.map { |t| f.type(t) }) }
    end

    # Filter by layer names
    # @param layers [Array<String>] Layer names to filter
    # @return [self] The selection set for chaining
    # @example Filter for entities on specific layers
    #   ss.filter_by_layer("WALLS", "DOORS")
    # @rbs *layers: Array[String]
    # @rbs return self
    def filter_by_layer(*layers)
      filter { |f| f.or(*layers.map { |l| f.layer(l) }) }
    end

    # Filter text entities containing specific text
    # @param text [String] Text pattern to search for (supports wildcards)
    # @return [self] The selection set for chaining
    # @example Find text containing "NOTE"
    #   ss.filter_text_containing("*NOTE*")
    # @rbs text: String
    # @rbs return self
    def filter_text_containing(text)
      filter do |f|
        f.and(f.has_text(text), f.or(f.type("TEXT"), f.type("MTEXT")))
      end
    end

    # Filter for block references with optional name
    # @param name [String, nil] Optional block name to filter
    # @return [self] The selection set for chaining
    # @example Filter for any block reference
    #   ss.filter_block_references
    # @example Filter for specific block
    #   ss.filter_block_references("DOOR")
    # @rbs name: String?
    # @rbs return self
    def filter_block_references(name = nil)
      filter { |f| f.block_reference(name) }
    end
  end
end
