# require_relative 'scan/scan_trait'
# require_relative "model_trait"

# require_relative 'ts/tagset_trait'
# require_relative 'graphics'
# require_relative 'ts/instance'

module Autocad
  module ModelTrait
    def each
      return enum_for(:each) unless block_given?
      @ole_obj.each do |ole|
        yield app.wrap(ole)
      end
    end

    def drawing
      @drawing ||= ::Autocad::Drawing.from_ole_obj(app, ole_obj.Document)
    end
  end

  class PaperSpace
    include ModelTrait
    attr_reader :app, :ole_obj

    def initialize(ole, app)
      @ole_obj = ole
      @app = app
    end
  end

  class ModelSpace
    include ModelTrait
    attr_reader :app, :ole_obj

    def initialize(ole, app)
      @ole_obj = ole
      @app = app
    end
  end
end
