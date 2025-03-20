# rbs_inline: enabled

module Autocad
  # Multi-line formatted text container in AutoCAD
  #
  # Represents a rich text entity with multiple lines and formatting.
  # Supports Liquid templates, table cell awareness, and line-by-line operations.
  #
  # @example Create and render a template
  #   specs = drawing.model.add_mtext("Project: {{name}}")
  #   specs.render(name: "Tower A")
  class MText < Element
    # @rbs attr_reader original: String
    # @rbs attr_reader ole_obj: WIN32OLE
    attr_reader :original, :ole_obj

    # Convert content to regex pattern
    #
    # @return [Regexp] A regular expression based on the text content
    # @rbs return Regexp
    def to_regexp
      Regexp.new(original.to_s)
    end

    # Check for empty content
    #
    # @return [Boolean] True if the MText has no content
    # @rbs return bool
    def empty?
      ole_obj.TextLinesCount == 0
    end

    # Type check for multi-line text (always true)
    #
    # @return [Boolean] Always returns true for MText objects
    # @rbs return bool
    def mtext?
      true
    end

    # Override text type check (always false)
    #
    # @return [Boolean] Always returns false for MText objects
    # @rbs return bool
    def text?
      false
    end

    # Get number of text lines
    #
    # @return [Integer] The number of lines in the MText
    # @rbs return Integer
    def size
      ole_obj.TextLinesCount
    end

    # Read content from OLE object
    #
    # @param ole [WIN32OLE] The OLE object to read from
    # @return [String] The text content
    # @rbs ole: WIN32OLE -> String
    def read_ole(ole)
      ole.TextString
    end

    # Update text content with cell awareness
    #
    # @param text [String] The new text content
    # @return [void]
    # @rbs text: String -> void
    def write_ole(text)
      if in_cell?
        write_ole_in_cell(text)
      else
        write_ole_regular(text)
      end
    end

    # Update text content for regular MText
    #
    # @param text [String] The new text content
    # @return [void]
    # @rbs text: String -> void
    def write_ole_regular(text)
      ole_obj.TextString = text
    end

    # Update text content for MText in table cell
    #
    # @param text [String] The new text content
    # @return [void]
    # @rbs text: String -> void
    def write_ole_in_cell(text)
      orig_ole = ole_obj
      new_text_ole = ole_obj.Clone
      new_text_ole.DeleteAllTextLines
      text.each_line do |line|
        new_text_ole.AddTextLine(line)
      end
      @ole_obj = new_text_ole
    rescue
      @ole_obj = orig_ole
    end

    # Full content rewrite with line-by-line updates
    #
    # @param text [String] The new text content
    # @return [void]
    # @rbs text: String -> void
    def update_ole!(text)
      ole_obj.DeleteAllTextLines
      text.each_line do |line|
        ole_obj.AddTextLine(line)
      end
      ole_obj.Redraw Autocad::MSD::MsdDrawingModeNormal
      ole_obj.Rewrite
    end

    # Get content as string
    #
    # @return [String] The text content
    # @rbs return String
    def to_s
      @original.to_s
    end

    # Regex pattern matching against text content
    #
    # @param reg [Regexp] The regular expression to match against
    # @return [Integer, nil] Match position or nil if no match
    # @rbs reg: Regexp -> Integer?
    def =~(reg)
      @original =~ reg
    end

    # Check for Liquid template placeholders
    #
    # @return [Boolean] True if the text contains template placeholders
    # @rbs return bool
    def template?
      !!(@original =~ /{{.+}}/)
    end

    # Render Liquid template with provided context
    #
    # @param h [Hash] The template variables
    # @return [self] The MText object
    # @example Render a template with variables
    #   mtext.render(client: "ABC Corp", floors: 42)
    # @rbs h: Hash[Symbol, untyped] -> self
    def render(h = {})
      return self unless template?

      template = Liquid::Template.parse(to_s)
      result = template.render(h)
      update(result) unless result == @original
      self
    end

    # Delegate uppercase methods to OLE object, lowercase to string methods
    #
    # @param meth [Symbol] The method name
    # @param * [Array] Method arguments
    # @param & [Proc] Optional block
    # @return [Object] Result of the method call
    # @rbs (Symbol, *untyped) -> untyped
    def method_missing(meth, *, &)
      if /^[A-Z]/.match?(meth)
        ole_obj.send(meth, *)
      else
        copy = @original.dup
        result = copy.send(meth, *, &)
        update(result) unless copy == @original
        result
      end
    end

    # def method_missing2(meth,*args,&block)
    #   if meth.to_s =~ /^[A-Z]/
    #     ole_obj.send(meth,*args)
    #   else
    #     dup = @original.dup
    #     result = dup.send(meth,*args,&block)
    #     _update(dup) unless dup == @original
    #     result
    #   end
    # end
  end
end
