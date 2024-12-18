module Autocad
  class Filter
    attr_reader :types, :values, :clauses

    def initialize(clauses: {})
      @clauses = clauses
      @types = []
      @values = []
    end

    def new_filter(clause, value)
      new_clauses = clauses.dup
      new_clauses[clause] = value
      Filter.new(clauses: new_clauses)
    end

    def has_filters?
      true
    end

    # convert the clauses to the values and types needed for autocad filter
    # rbs return Array[Array,Array] -- the types and values array
    def convert_clauses
      types = []
      values = []

      case clauses.keys.first
      when :type
        types << 0
        values << clauses[:type]
      when :layer
        types << 8
        values << clauses[:layer]
      when :color
        types << 62
        values << clauses[:color]
      when :block_reference
        types << 0
        values << 'INSERT'
      when :paper_space
        types << 67
        values << 1
      when :model_space
        types << 67
        values << 0
      when :text_content
        types << 1  # DXF type code 1 for text content
        values << clauses[:text_content]
      when :and, :or, :xor
        operator = clauses.keys.first.to_s.upcase
        types << -4
        values << "<#{operator}"
        
        clauses[clauses.keys.first].each do |condition|
          sub_types, sub_values = condition.convert_clauses
          types.concat(sub_types)
          values.concat(sub_values)
        end
        
        types << -4
        values << "#{operator}>"
      when :not
        types << -4
        values << '<NOT'
        
        sub_types, sub_values = clauses[:not].convert_clauses
        types.concat(sub_types)
        values.concat(sub_values)
        
        types << -4
        values << 'NOT>'
      when :gt
        types.concat([-4, 40])
        values.concat(['>=', clauses[:gt]])
      when :lt
        types.concat([-4, 40])
        values.concat(['<=', clauses[:lt]])
      when :eq
        types.concat([-4, 40])
        values.concat(['=', clauses[:eq]])
      when :neq
        types.concat([-4, 40])
        values.concat(['<>', clauses[:neq]])
      end

      [types, values]
    end

    # Logical Operators
    def and(*conditions)
      new_filter(:and, conditions)
      # return self if conditions.empty?

      # @types << -4
      # @values << '<AND'

      # conditions.each do |condition|
      #   @types.concat(condition.types)
      #   @values.concat(condition.values)
      # end

      # @types << -4
      # @values << 'AND>'

      # self
    end

    def merge_conditions(existing, new_condition)
    end

    def or(*conditions)
      new_filter(:or, conditions)
      # return self if conditions.empty?

      # @types << -4
      # @values << '<OR'

      # conditions.each do |condition|
      #   @types.concat(condition.types)
      #   @values.concat(condition.values)
      # end

      # @types << -4
      # @values << 'OR>'

      # self
    end

    def xor(condition1, condition2)
      new_filter(:xor, [condition1, condition2])
      # @types << -4
      # @values << '<XOR'

      # @types.concat(condition1.types)
      # @values.concat(condition1.values)

      # @types.concat(condition2.types)
      # @values.concat(condition2.values)

      # @types << -4
      # @values << 'XOR>'

      # self
    end

    def not(condition)
      new_filter(:not, condition)
      # @types << -4
      # @values << '<NOT'

      # @types.concat(condition.types)
      # @values.concat(condition.values)

      # @types << -4
      # @values << 'NOT>'

      # self
    end

    # Relational Operators
    #  f.type("Circle").greater_than(5)
    def greater_than(value)
      new_filter(:gt, value)
      # @types << -4
      # @values << '>='
      # @types << 40 # floating point
      # @values << value
      # self
    end

    def less_than(value)
      new_filter(:lt, value)
      # @types << -4
      # @values << '<='
      # @types << 40 # floating point
      # @values << value
      # self
    end

    def equal_to(value)
      new_filter(:eq, value)
      # @types << -4
      # @values << '='
      # @types << 40 # floating point
      # @values << value
      # self
    end

    def not_equal_to(value)
      new_filter(:neq, value)
      # @types << -4
      # @values << '<>'
      # @types << 40 # floating point
      # @values << value
      # self
    end

    def block_reference(name = nil)
      new_filter(:block_reference, name)
      # # return unless name

      # @types << 0
      # @values << 'INSERT'
      # self
    end

    def name(value)
      new_filter(:name, value)
      # @types << [0, 2]
      # @values << value
      # self
    end

    def type(kind)
      new_filter(:type, kind)
      # @types << 0
      # @values << kind
      # self
    end

    def layer(name)
      new_filter(:layer, name)
      # @types << 8
      # @values << name
      # self
    end

    def visible(vis = true)
      new_filter(:visible, vis)
      # @types << 60
      # @values << (vis ? 0 : 1)
      # self
    end

    def color(num)
      new_filter(:color, num)
      # @types << 62 # Color number filter
      # @values << num
      # self
    end

    def paper_space
      new_filter(:paper_space, nil)
      # @types << 67  # Paper space filter
      # @values << 1
      # self
    end

    def model_space
      new_filter(:model_space, nil)
      # @types << 67  # Model space filter
      # @values << 0
      # self
    end

    def contains(str)
      new_filter(:text_content, str)
    end
  end
end
