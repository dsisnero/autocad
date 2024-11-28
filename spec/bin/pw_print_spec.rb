require_relative "../spec_helper"

describe "pw_print command" do
  let(:fixtures_dir) { Pathname.new(__dir__).join("../fixtures").expand_path }
  
  before do
    @original_dir = Dir.pwd
    Dir.chdir(fixtures_dir)
  end

  after do
    Dir.chdir(@original_dir)
  end

  describe "PwApp" do
    it "handles missing directory gracefully" do
      output = `ruby ../../bin/pw_print nonexistent`
      _(output).must_match(/doesn't exist/)
      _($?.exitstatus).wont_equal 0
    end

    it "accepts optional directory argument" do
      Dir.mktmpdir do |dir|
        output = `ruby ../../bin/pw_print #{dir}`
        _($?.exitstatus).must_equal 0
      end
    end

    it "uses current directory when no arg given" do
      output = `ruby ../../bin/pw_print`
      _($?.exitstatus).must_equal 0
    end

    it "respects --no-exit flag" do
      Dir.mktmpdir do |dir|
        output = `ruby ../../bin/pw_print --no-exit #{dir}`
        _($?.exitstatus).must_equal 0
      end
    end

    it "shows version info" do
      output = `ruby ../../bin/pw_print --version`
      _(output).must_match(/\d+\.\d+\.\d+/)
      _($?.exitstatus).must_equal 0
    end

    it "shows help info" do
      output = `ruby ../../bin/pw_print --help`
      _(output).must_match(/Usage:/)
      _(output).must_match(/Options:/)
      _($?.exitstatus).must_equal 0
    end
  end
end
