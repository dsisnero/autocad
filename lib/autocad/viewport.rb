require_relative "element"

module Autocad
  class Viewport < Element
    def width
      @ole_obj.Width
    end

    def height
      @ole_obj.Height
    end

    def each
      return enum_for(:each) unless block_given?
      @ole_obj.each do |ole|
        yield app.wrap(ole)
      end
    end
  end
end
