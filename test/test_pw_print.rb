require "test_helper"
require "tmpdir"
require_relative "../exe/pw_print"

class TestPwPrint < Minitest::Test
  def setup
    @temp_dir = Pathname.new(Dir.mktmpdir)
    @mock_app = Minitest::Mock.new
  end

  def teardown
    FileUtils.remove_entry @temp_dir
  end

  def test_saves_to_specified_directory_with_exit
    mock = Minitest::Mock.new
    mock.expect :call, @mock_app, [@temp_dir, {exit: true}]
    
    Autocad.stub :save_current_drawing, mock do
      args = ["--save-dir", @temp_dir.to_s, "--exit"]
      
      assert_silent do
        PwApp.run(args)
      end
    end
    
    mock.verify
  end

  def test_saves_to_specified_directory_without_exit
    mock = Minitest::Mock.new
    mock.expect :call, @mock_app, [@temp_dir, {exit: false}]
    
    Autocad.stub :save_current_drawing, mock do
      args = ["--save-dir", @temp_dir.to_s, "--no-exit"]
      
      assert_silent do
        PwApp.run(args)
      end
    end
    
    mock.verify
  end

  def test_uses_current_directory_when_no_save_dir_specified
    current_dir = Pathname.getwd
    mock = Minitest::Mock.new
    mock.expect :call, @mock_app, [current_dir, {exit: true}]
    
    Autocad.stub :save_current_drawing, mock do
      args = ["--exit"]
      
      assert_silent do
        PwApp.run(args)
      end
    end
    
    mock.verify
  end

  def test_raises_error_when_save_directory_does_not_exist
    nonexistent_dir = @temp_dir + "nonexistent"
    args = ["--save-dir", nonexistent_dir.to_s]

    error = assert_raises(SystemExit) do
      PwApp.run(args)
    end
    
    assert_match(/directory: #{nonexistent_dir} doesn't exist/, error.message)
  end

  def test_displays_help_information
    output = assert_raises(SystemExit) do
      PwApp.run(["--help"])
    end
    
    assert_output(/Save the currently open projectwise drawing/) do
      PwApp.run(["--help"]) rescue nil
    end
  end

  def test_displays_version_information
    output = assert_raises(SystemExit) do
      PwApp.run(["--version"])
    end
    
    assert_output(/#{Autocad::VERSION}/) do
      PwApp.run(["--version"]) rescue nil
    end
  end

  def test_log_level_option
    mock = Minitest::Mock.new
    mock.expect :call, @mock_app, [Pathname.getwd, {exit: true}]
    
    Autocad.stub :save_current_drawing, mock do
      args = ["--log-level", "DEBUG"]
      
      assert_silent do
        PwApp.run(args)
      end
    end
    
    mock.verify
  end
end
