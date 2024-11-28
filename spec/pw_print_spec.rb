# frozen_string_literal: true

require "spec_helper"
require "pathname"
require "fileutils"
require "tempfile"

describe PwApp do
  let(:temp_dir) { Pathname(Dir.mktmpdir) }
  let(:mock_app) { Minitest::Mock.new }
  let(:mock_drawing) { Minitest::Mock.new }

  before do
    FileUtils.mkdir_p(temp_dir)
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe "#main" do
    it "saves current drawing when directory exists" do
      mock_drawing.expect :copy, nil, [{ dir: temp_dir }]
      mock_drawing.expect :save_as_pdf, nil, [{ dir: temp_dir }]
      mock_drawing.expect :close, nil, [false]
      
      mock_app.expect :current_drawing, mock_drawing

      Autocad.stub :run, nil, mock_app do |&block|
        block.call(mock_app)
      end

      # Simulate CLI arguments
      ARGV.replace(["--save-dir", temp_dir.to_s])
      
      # Run the CLI
      PwApp.new.execute

      mock_app.verify
      mock_drawing.verify
    end

    it "fails when directory doesn't exist" do
      non_existent_dir = Pathname("/path/that/does/not/exist")
      
      # Simulate CLI arguments
      ARGV.replace(["--save-dir", non_existent_dir.to_s])
      
      error = assert_raises(SystemExit) do
        PwApp.new.execute
      end
      
      assert_match(/doesn't exist/, error.message)
    end

    it "respects the no-exit option" do
      mock_drawing.expect :copy, nil, [{ dir: temp_dir }]
      mock_drawing.expect :save_as_pdf, nil, [{ dir: temp_dir }]
      
      mock_app.expect :current_drawing, mock_drawing

      Autocad::App.stub :new, mock_app do
        # Simulate CLI arguments
        ARGV.replace(["--save-dir", temp_dir.to_s, "--no-exit"])
        
        app = PwApp.new.execute
        assert_equal mock_app, app
      end

      mock_app.verify
      mock_drawing.verify
    end
  end
end
