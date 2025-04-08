require_relative '../../spec_helper'

describe Autocad::PaperSpace do
  before(:all) do
    @app = Autocad::App.new(visible: false)
    @drawing = @app.new_drawing("paper_space_test_#{Time.now.to_i}.dwg")
  end

  after(:all) do
    begin
      @drawing.close(save: false) if @drawing
    rescue StandardError => e
      puts "Error closing drawing: #{e.message}"
    end
    @app.quit
  end

  describe '#pviewports' do
    it 'returns an empty array when no viewports exist' do
      paper_space = @drawing.paper_space
      paper_space.clear_pviewports

      viewports = paper_space.pviewports
      _(viewports).must_be_empty
    end

    it 'returns viewports when they exist' do
      paper_space = @drawing.paper_space
      paper_space.clear_pviewports

      # Add a viewport
      viewport = paper_space.add_pv_viewport([5, 5, 0], width: 10, height: 8)

      viewports = paper_space.pviewports
      _(viewports).wont_be_empty
      _(viewports.first).must_be_kind_of(Autocad::PViewport)
    end
  end

  describe '#add_pv_viewport' do
    it 'creates a viewport at the specified location with given dimensions' do
      paper_space = @drawing.paper_space
      paper_space.clear_pviewports

      center = [10, 10, 0]
      width = 15
      height = 10

      viewport = paper_space.add_pv_viewport(center, width: width, height: height)

      _(viewport).must_be_kind_of(Autocad::PViewport)
      _(viewport.width).must_be_close_to(width, 0.001)
      _(viewport.height).must_be_close_to(height, 0.001)
    end
  end

  describe '#clear_pviewports' do
    it 'removes all viewports from paper space' do
      paper_space = @drawing.paper_space

      # Add a couple of viewports
      paper_space.add_pv_viewport([5, 5, 0], width: 10, height: 8)
      paper_space.add_pv_viewport([20, 20, 0], width: 12, height: 9)

      # Verify they exist
      _(paper_space.pviewports.count).must_be :>, 0

      # Clear them
      paper_space.clear_pviewports

      # Verify they're gone
      _(paper_space.pviewports).must_be_empty
    end
  end
end
