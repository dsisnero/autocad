require_relative 'selection_filter'

module Autocad
  class SelectionSet
    attr_reader :filter_types, :filter_values, :name

    def initialize(name)
      @name = name
      @filter_types = []
      @filter_values = []
    end

    def has_filter?
      filter_types && filter_types.any?
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

    def to_ole_filter_type
      return nil unless has_filter?
      filter_types
    end

    def to_ole_filter_value
      return nil unless has_filter?
      filter_values
    end

    # filter do |f|
    #   st = f.type('Circle').or(f.type('Arc'))
    #   st2 = f.layer('0').or(f.layer('1'))
    #   f.and(st, st2)
    # end
    #
    def filter
      filter = SelectionFilter.new
      result = yield filter
      return unless result.has_filters?

      @filter_types = result.types.flatten
      @filter_values = result.values.flatten
      self
    end

    # Helper methods for common operations
    def filter_by_type(*types)
      filter { |f| f.or(*types.map { |t| f.type(t) }) }
    end

    def filter_by_layer(*layers)
      filter { |f| f.or(*layers.map { |l| f.layer(l) }) }
    end

    def filter_text_containing(text)
      filter { |f| f.and(f.or(f.type('TEXT'), f.type('MTEXT')), f.contains(text)) }
    end

    def filter_block_references(name = nil)
      filter { |f| f.block_reference(name) }
    end
  end
end
