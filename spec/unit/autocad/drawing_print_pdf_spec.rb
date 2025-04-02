require_relative '../../spec_helper'

describe Autocad::Drawing do
  before(:all) do
    @app = Autocad::App.new(visible: false)
    @temp_files = []
    @temp_pdfs = []
  end

  after(:all) do
    # Close any remaining drawings
    begin
      @app.close_all_drawings(save: false)
    rescue StandardError => e
      puts "Error closing drawings: #{e.message}"
    end

    # Force quit the app to ensure all files are released
    @app.quit

    # Clean up any temp files
    @temp_files.each do |path|
      File.delete(path) if path && File.exist?(path)
    rescue StandardError => e
      puts "Error deleting file #{path}: #{e.message}"
    end

    # Clean up any PDF files
    @temp_pdfs.each do |path|
      File.delete(path) if path && File.exist?(path)
    rescue StandardError => e
      puts "Error deleting PDF file #{path}: #{e.message}"
    end
  end

  describe 'when printing to PDF' do
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
        rescue StandardError => app_err
          puts "Error in app.close_drawing: #{app_err.message}"
        end
      rescue StandardError => e
        puts "Error closing drawing #{drawing.name}: #{e.message}"
      ensure
        # Make sure drawing is nil to prevent further use
        drawing = nil
      end
    end

    let(:drawing) { @app.new_drawing("test_print.dwg") }
    let(:pdf_path) { Pathname.new(Dir.tmpdir).join("test_print_#{Time.now.to_i}.pdf") }

    it 'creates a PDF file using default plot configuration' do
      # Add some content to the drawing to make it more realistic
      drawing.model.add_circle([0, 0, 0], 10)
      drawing.save

      # Print to PDF using default configuration
      drawing.print_pdf(pdf_path)
      
      # Track PDF for cleanup
      @temp_pdfs << pdf_path

      # Verify the PDF was created
      _(File.exist?(pdf_path)).must_equal true
      _(File.size(pdf_path)).must_be :>, 0
    end

    it 'creates a PDF file using custom plot configuration' do
      # Add some content to the drawing
      drawing.model.add_rectangle([-10, -10, 0], [10, 10, 0])
      drawing.save

      # Create a custom plot configuration
      custom_config = drawing.add_plot_configuration("custom_pdf_config")
      custom_config.setup(
        device_name: "AutoCAD PDF (High Quality Print).pc3",
        media_name: "ANSI_B_(17.00_x_11.00_Inches)",
        style_sheet: "monochrome.ctb",
        plot_type: :layout
      )

      # Print to PDF using custom configuration
      custom_pdf_path = Pathname.new(Dir.tmpdir).join("test_print_custom_#{Time.now.to_i}.pdf")
      drawing.print_pdf(custom_pdf_path, plot_config: custom_config)
      
      # Track PDF for cleanup
      @temp_pdfs << custom_pdf_path

      # Verify the PDF was created
      _(File.exist?(custom_pdf_path)).must_equal true
      _(File.size(custom_pdf_path)).must_be :>, 0
    end

    it 'handles model space printing when model flag is true' do
      # Add some content to model space
      drawing.model.add_line([-5, -5, 0], [5, 5, 0])
      drawing.save

      # Print model space to PDF
      model_pdf_path = Pathname.new(Dir.tmpdir).join("test_print_model_#{Time.now.to_i}.pdf")
      
      # Capture output to verify it's printing model space
      output = capture_io do
        drawing.print_pdf(model_pdf_path, model: true)
      end
      
      # Track PDF for cleanup
      @temp_pdfs << model_pdf_path

      # Verify output indicates model space printing
      _(output.join).must_match(/print model/)
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
