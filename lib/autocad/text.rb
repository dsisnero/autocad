# rbs_inline: enabled

require_relative "element"

module Autocad
  # Single-line text annotation element in AutoCAD
  #
  # Represents a simple text entity with a single line of content.
  # Provides methods for reading, writing, and manipulating text properties.
  #
  # @example Create and modify text
  #   text = drawing.model.add_text("Label", [10,5,0])
  #   text.height = 2.5
  #   text.update("New Label")
  class Text < Element
    # Read text content from OLE object
    #
    # @param _ole [WIN32OLE] The OLE object to read from (unused parameter)
    # @return [String] The text content
    # @rbs (_ole: WIN32OLE) -> String
    def read_ole(_ole)
      ole_obj.TextString
    end

    # Confirm this is a text element (always true)
    #
    # @return [Boolean] Always returns true for Text objects
    # @rbs return bool
    def text?
      true
    end

    # Update text content in AutoCAD
    #
    # @param text [String] The new text content
    # @return [void]
    # @rbs text: String -> void
    def write_ole(text)
      ole_obj.TextString = text
    end

    # Convert text content to regex pattern
    #
    # @return [Regexp] A regular expression based on the text content
    # @rbs return Regexp
    def to_regexp
      Regexp.new(read_ole.to_s)
    end

    # Toggle text highlighting in the drawing
    #
    # @param flag [Boolean] Whether to highlight (true) or unhighlight (false)
    # @return [void]
    # @example Highlight selected text
    #   selected_text.each { |t| t.highlight }
    # @rbs flag: bool -> void
    def highlight(flag = true)
      ole_obj.Highlight(flag)
      ole_obj.Update
    end

    # Regex pattern matching against text content
    #
    # @param reg [Regexp] The regular expression to match against
    # @return [Integer, nil] Match position or nil if no match
    # @rbs reg: Regexp -> Integer?
    def =~(reg)
      @original =~ reg
    end

    # Get text content as string
    #
    # @return [String] The text content
    # @rbs return String
    def to_s
      original.to_s
    end

    # Experimental bounding box calculation
    #
    # @return [BoundingBox] The text's bounding box
    # @note Contains debug code - use with caution
    # @rbs return BoundingBox
    def bounds
      binding.break
      rotation = ole_obj.Rotation
      begin
        app_ole_obj.Matrix3dInverse(rotation)
      rescue
        binding.irb
      end
      transform = app_ole_obj.Transform3dFromMatrix3dandFixedPoint3d(app_ole_obj.Matrix3dInverse(rotation),
        ole_obj.origin)
      ole_obj.transform transform

      0.upto(4) do |i|
        points[i] = ole_obj.Boundary.Low
      end
      points[2] = self.Boundary.High
      points[1].X = points[2].x
      points[3].y = points[2].Y
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
        dup = @original.dup
        result = dup.send(meth, *, &)
        update(result)
        result
      end
    end

    # def method_missing(meth,*args,&block)
    #   dup = @original_text.dup
    #     result = dup.send(meth,*args, &block)
    #     _update(dup) unless dup == @original_text
    #   result
    # end
  end
end
