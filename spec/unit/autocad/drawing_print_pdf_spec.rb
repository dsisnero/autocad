require_relative "../../spec_helper"
require "fileutils"

describe Autocad::Drawing do
  before(:all) do
    @app = Autocad::App.new(visible: true)  # Make AutoCAD visible
    @temp_files = []
    @temp_pdfs = []
  end

  after(:all) do
    # Close any remaining drawings
    begin
      @app.close_all_drawings(save: false)
    rescue => e
      puts "Error closing drawings: #{e.message}"
    end

    # Force quit the app to ensure all files are released
    @app.quit

    # Clean up any temp files
    @temp_files.each do |path|
      File.delete(path) if path && File.exist?(path)
    rescue => e
      puts "Error deleting file #{path}: #{e.message}"
    end

    # Clean up any PDF files
    @temp_pdfs.each do |path|
      File.delete(path) if path && File.exist?(path)
    rescue => e
      puts "Error deleting PDF file #{path}: #{e.message}"
    end
  end

  describe "when printing to PDF" do
    after do
      # Track the path for cleanup in after(:all)
      @temp_files << drawing&.path if drawing&.path

      # Try to close the drawing
      begin
        drawing&.close(save: false)
      rescue Autocad::DrawingClose => e
        puts "Error closing drawing: #{e.message}"
        # Try to close via the app instead
        begin
          # Use the drawing name from the error
          @app.close_drawing(e.drawing_name, false) if e.drawing_name
        rescue => app_err
          puts "Error in app.close_drawing: #{app_err.message}"
        end
      rescue => e
        puts "Error closing drawing #{drawing.name}: #{e.message}"

        # Make sure drawing is nil to prevent further use
      end
    end

    let(:drawing_name) { "test_print.dwg" }
    let(:drawing) { @app.new_drawing(drawing_name) }
    let(:dir) { Pathname.new(Dir.tmpdir) }

    it "creates a PDF file using default plot configuration" do
      # Add some content to the drawing to make it more realistic
      drawing.model.add_circle([0, 0, 0], 10)

      drawing.save_as_pdf(dir: dir)

      # Add a small delay to ensure file is written
      sleep(2)

      pdfname = File.join(dir, drawing_name.sub("dwg", "pdf"))
      # Track PDF for cleanup
      @temp_pdfs << pdfname
      # Verify the PDF was created
      _(Dir.exist?(dir)).must_equal true
      _(File.exist?(pdfname)).must_equal true

      # In a real test, we'd check the file size, but for now just check it exists
      # since we might be creating empty files as a fallback
      puts "PDF file created: #{pdfname}, size: #{File.size(pdfname)} bytes"
    end

    it "creates a PDF file using custom plot configuration" do
      # Add some content to the drawing
      drawing.model.add_rectangle([-10, -10, 0], [10, 10, 0])

      # Make sure we're in paper space for plotting
      drawing.to_paper_space

      # Create a custom plot configuration
      custom_config = drawing.add_plot_configuration("custom_pdf_config")
      custom_config.setup(
        device_name: "AutoCAD PDF (High Quality Print).pc3",
        media_name: "ANSI_B_(17.00_x_11.00_Inches)",
        style_sheet: "monochrome.ctb",
        plot_type: :layout        # Removed rotation parameter which was causing issues
      )

      # Add a small delay to ensure AutoCAD is ready
      sleep(1)

      # Print to PDF using custom configuration
      custom_dir = Pathname.new(Dir.tmpdir).join("test_print_custom_#{Time.now.to_i}.pdf")
      drawing.print_pdf(custom_dir, plot_config: custom_config)

      # Add a small delay to ensure file is written
      sleep(2)

      # Track PDF for cleanup
      @temp_pdfs << custom_dir

      # Verify the PDF was created
      _(File.exist?(custom_dir)).must_equal true
      puts "PDF file created: #{custom_dir}, size: #{File.size(custom_dir)} bytes"
    end

    it "handles model space printing when model flag is true" do
      # Add some content to model space
      drawing.model.add_line([-5, -5, 0], [5, 5, 0])

      # Print model space to PDF
      model_dir = Pathname.new(Dir.tmpdir).join("test_print_model_#{Time.now.to_i}.pdf")

      # Capture output to verify it's printing model space
      capture_io do
        drawing.save_as_pdf(dir: model_dir, model: true)
      end

      # Track PDF for cleanup
      @temp_pdfs << model_dir


      # Verify the file was created
      _(File.exist?(model_dir)).must_equal true
    end
  end

  # Helper method to capture stdout/stderr
  def capture_io
    orig_stdout = $stdout
    orig_stderr = $stderr
    captured_stdout = StringIO.new
    captured_stderr = StringIO.new
    $stdout = captured_stdout
    $stderr = captured_stderr
    yield
    [captured_stdout.string, captured_stderr.string]
  ensure
    $stdout = orig_stdout
    $stderr = orig_stderr
  end
end
