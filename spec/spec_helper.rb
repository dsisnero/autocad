# frozen_string_literal: true

# require "pw_print"

require "minitest/autorun"
require "minitest/spec"
require "minitest/mock"
require "pathname"
require "tmpdir"
require "fileutils"
require "acrobat"

TEST_DIR = Pathname.new(__dir__)
FIXTURES_DIR = TEST_DIR.join("fixtures")
FIXTURES_DIR.mkpath unless FIXTURES_DIR.exist?
ROOT = TEST_DIR.parent
LIB_DIR = ROOT.join("lib")

TEMP_DIR = TEST_DIR.join("temp")
TEMP_DIR.mkpath unless TEMP_DIR.exist?
$LOAD_PATH.unshift LIB_DIR
# $LOAD_PATH.unshift File.expand_path("../exe", __dir__)

require "autocad"

module TestHelper
  def fixture_file(name)
    FIXTURES_DIR.join(name)
  end

  def temp_dir
    TEMP_DIR
  end

  def temp_file(name)
    TEMP_DIR.join(name)
  end

  # copies a test drawing to a temp directory
  # yields the path
  # ensures that the temp drawing is deleted
  def with_test_drawing(original_name)
    temp_path = setup_test_drawing(original_name)
    yield temp_path
  ensure
    cleanup_test_drawing(original_name)
  end

  def setup_test_drawing(original_name)
    basename = original_name.basename
    source = fixture_file(basename)
    temp_path = temp_file(basename).expand_path
    FileUtils.cp(source, temp_path)
    temp_path
  end

  def cleanup_test_drawing(filename)
    path = temp_file(filename.basename).expand_path
    binding.irb
    Acrobat::App.close(path.sub_ext(".pdf"))
    path.delete if path.exist?
  end

  def assert_drawing_matches(test_drawing, reference_drawing)
    assert File.exist?(test_drawing), "Test drawing does not exist: #{test_drawing}"
    assert File.exist?(reference_drawing), "Reference drawing does not exist: #{reference_drawing}"

    # Basic file integrity check
    test_size = File.size(test_drawing)
    ref_size = File.size(reference_drawing)
    assert test_size > 0, "Test drawing is empty"
    assert ref_size > 0, "Reference drawing is empty"

    # Open both drawings to compare properties
    test_app = Microstation::App.new
    ref_app = Microstation::App.new

    begin
      test_dwg = test_app.open_drawing(test_drawing)
      ref_dwg = ref_app.open_drawing(reference_drawing)

      # Compare basic properties
      assert_equal ref_dwg.name, test_dwg.name, "Drawing names don't match"

      # Compare models
      test_models = test_dwg.models
      ref_models = ref_dwg.models
      assert_equal ref_models.count, test_models.count, "Model count mismatch"

      # Compare elements if needed
      # test_elements = test_dwg.scan_elements.to_a
      # ref_elements = ref_dwg.scan_elements.to_a
      # assert_equal ref_elements.count, test_elements.count, "Element count mismatch"
    ensure
      begin
        test_app.close_active_drawing
      rescue
        nil
      end
      begin
        ref_app.close_active_drawing
      rescue
        nil
      end
    end
  end

  def with_temp_drawing(original_name)
    app = Microstation::App.new
    binding.irb unless File.exist?(original_name)

    config_app(app)
    temp_path = setup_test_drawing(original_name)

    drawing = nil
    begin
      drawing = app.open_drawing(temp_path)
      yield drawing if block_given?
    ensure
      begin
        app.close_active_drawing
      rescue
        nil
      end
      cleanup_test_drawing(original_name)
    end
    binding.irb if File.exist?(temp_path)
    binding.irb unless File.exist?(original_name)
  end

  def cleanup_temp_files
    TEMP_DIR.children.each do |file|
      File.delete(file)
    end
  end

  def normalize_path(p)
    p.to_s.sub(/[c,C]:/, "C:")
  end

  # Test drawing management helpers
end
