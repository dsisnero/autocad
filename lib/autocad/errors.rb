module Autocad
  Error = Class.new(::RuntimeError)
  NonDGNFile = Class.new(Error)
  FileNotFound = Class.new(Error)
  MultipleUpdateError = Class.new(Error)

  # class RetryableError < Error
  #   attr_reader :num_tries
  #   def initialize(message, num_tries)
  #     @num_tries = num_tries
  #     super("#{message} (##{num_tries})")
  #   end
  # end

  class DrawingError < Error
    attr_reader :drawing

    def initialize(message, drawing)
      @drawing = drawing
      super("#{message} for #{drawing.path}")
    end
  end

  class ExistingFile < Error
    def initialize(path)
      msg = "File at path #{path} already exists"
      super(msg)
    end
  end
end
