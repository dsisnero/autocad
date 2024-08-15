module Autocad
  class Enumerator
    include Enumerable

    attr_reader :app

    def initialize(ole, app)
      @ole_obj = ole
      @app = app
    end

    def each
      return enum_for(:each) unless block_given?

      @ole_obj.each do |ole|
        yield app.wrap(ole)
      end
    end

    def reset
      @ole_obj.reset
    end
  end
end
