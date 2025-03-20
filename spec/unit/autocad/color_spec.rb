require_relative '../../spec_helper'

describe Autocad::Color do
  describe '.to_index' do
    it 'returns the integer value for a color constant' do
      _(Autocad::Color.to_index(:red)).must_equal 1
      _(Autocad::Color.to_index(:blue)).must_equal 5
      _(Autocad::Color.to_index(:green)).must_equal 3
    end

    it 'accepts string color names' do
      _(Autocad::Color.to_index('RED')).must_equal 1
      _(Autocad::Color.to_index('blue')).must_equal 5
    end

    it 'accepts camelCase color names' do
      _(Autocad::Color.to_index('darkRed')).must_equal 10
      _(Autocad::Color.to_index('lightGray')).must_equal 9
    end

    it 'accepts snake_case color names' do
      _(Autocad::Color.to_index('dark_red')).must_equal 10
      _(Autocad::Color.to_index('light_gray')).must_equal 9
    end

    it 'passes through integer values' do
      _(Autocad::Color.to_index(1)).must_equal 1
      _(Autocad::Color.to_index(42)).must_equal 42
    end

    it 'raises an error for unknown color names' do
      assert_raises(ArgumentError) { Autocad::Color.to_index(:not_a_color) }
    end
  end

  describe '.from_index' do
    it 'returns the symbolic name for known color indices' do
      _(Autocad::Color.from_index(1)).must_equal :red
      _(Autocad::Color.from_index(5)).must_equal :blue
    end

    it 'returns snake_case names for camelCase constants' do
      _(Autocad::Color.from_index(9)).must_equal :light_gray
      _(Autocad::Color.from_index(10)).must_equal :dark_red
    end

    it 'returns the original index for unknown color indices' do
      _(Autocad::Color.from_index(42)).must_equal 42
    end
  end
end

describe Autocad::Layer do
  before(:all) do
    @app = Autocad::App.new(visible: false)
    @drawing = @app.new_drawing("color_test_#{Time.now.to_i}.dwg")
  end

  after(:all) do
    begin
      @drawing.close(save: false) if @drawing
    rescue StandardError => e
      puts "Error closing drawing: #{e.message}"
    end
    @app.quit
  end

  describe '#color and #color=' do
    it 'sets and gets the color using integer values' do
      layer = @drawing.create_layer('ColorTestLayer1')
      layer.color = 1 # Red
      _(layer.color).must_equal 1
    end

    it 'sets the color using symbolic names' do
      layer = @drawing.create_layer('ColorTestLayer2')
      layer.color = :blue
      _(layer.color).must_equal 5 # Blue is 5 in AutoCAD
    end

    it 'sets the color using string names' do
      layer = @drawing.create_layer('ColorTestLayer3')
      layer.color = 'GREEN'
      _(layer.color).must_equal 3 # Green is 3 in AutoCAD
    end

    it 'sets the color using Autocad::Color constants' do
      layer = @drawing.create_layer('ColorTestLayer4')
      layer.color = Autocad::Color::Magenta
      _(layer.color).must_equal 6 # Magenta is 6 in AutoCAD
    end
  end

  describe '#color_name' do
    it 'returns the symbolic name for known colors' do
      layer = @drawing.create_layer('ColorNameLayer1')
      layer.color = 1 # Red
      _(layer.color_name).must_equal :red
    end

    it 'returns the original index for unknown colors' do
      layer = @drawing.create_layer('ColorNameLayer2')
      layer.color = 42 # Some arbitrary color
      _(layer.color_name).must_equal 42
    end
  end

  describe 'Drawing#create_layer with color' do
    it 'creates a layer with the specified integer color' do
      layer = @drawing.create_layer('CreateColorLayer1', 3)
      _(layer.color).must_equal 3 # Green
    end

    it 'creates a layer with the specified symbolic color' do
      layer = @drawing.create_layer('CreateColorLayer2', :red)
      _(layer.color).must_equal 1 # Red
    end

    it 'creates a layer with the specified Autocad::Color constant' do
      layer = @drawing.create_layer('CreateColorLayer3', Autocad::Color::Blue)
      _(layer.color).must_equal 5 # Blue
    end
  end
end
