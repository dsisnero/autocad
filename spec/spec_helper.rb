# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "autocad"

require "minitest/autorun"
require "minitest/spec"
require "pathname"
require "mocha/minitest"
require "fileutils"
require "tmpdir"

class Minitest::Spec
  # Helper for AutoCAD-dependent tests
  def with_mocked_autocad
    # Stub the OLE connection
    Autocad::App.any_instance.stubs(:init_ole_and_app_event).returns([
      mock('OLE'), 
      mock('AppEvent')
    ])
    
    # Stub base AutoCAD functionality
    yield.tap do
      Autocad::App.any_instance.unstub(:init_ole_and_app_event)
    end
  end

  # Create temp directory for tests that need file operations
  def with_temp_dir
    Dir.mktmpdir do |dir|
      @temp_dir = Pathname.new(dir)
      yield
    ensure 
      @temp_dir = nil
    end
  end
  
  def create_mock_drawing(path)
    FileUtils.touch(path)
    Pathname.new(path)
  end

  def stub_drawing_operations(app)
    mock_drawing = mock('Drawing')
    app.stubs(:open_drawing).yields(mock_drawing)
    app.stubs(:new_drawing).yields(mock_drawing)
    mock_drawing
  end
end
