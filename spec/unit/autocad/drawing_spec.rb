require_relative '../../spec_helper'

describe Autocad::Drawing do
  before(:all) do
    @app = Autocad::App.new(visible: false)
    @temp_files = []
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
  end

  describe 'when using a new drawing' do
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

    let(:drawing) { @app.new_drawing("test_#{Time.now.to_i}.dwg") }

    it '#path should return a pathname' do
      _(drawing.path).must_be_instance_of(Pathname)
    end

    it '#active_space should return the correct model' do
      drawing.to_model_space
      _(drawing.active_space).must_be_instance_of(Autocad::ModelSpace)
      drawing.to_paper_space
      _(drawing.active_space).must_be_instance_of(Autocad::PaperSpace)
    end

    it '#selection_sets should return an enumerator when no block given' do
      _(drawing.selection_sets).must_be_kind_of(Enumerator)
    end

    it '#selection_sets should yield selection sets when block given' do
      sets = []
      drawing.selection_sets { |set| sets << set }
      sets.each do |set|
        _(set).must_be_instance_of(Autocad::SelectionSetAdapter)
      end
    end

    describe '#create_selection_set' do
      it 'must create a selection set' do
        ss = drawing.selection_sets.find { |s| s.name == 'test' }
        _(ss).must_be_nil
        drawing.create_selection_set('test')
        ss = drawing.selection_sets.find { |s| s.name == 'test' }

        _(ss).must_be_kind_of Autocad::SelectionSetAdapter
        _(ss.name).must_equal 'test'
      end

      it 'accepts a block to configure the selection set' do
        ss = drawing.create_selection_set('test_with_block') do |s|
          s.filter_types = ['TEXT']
        end
        _(ss).must_be_kind_of Autocad::SelectionSetAdapter
        _(ss.name).must_equal 'test_with_block'
      end
    end

    describe '#get_variables' do
      it 'returns an array with the variable current values' do
        vars = drawing.get_variables('nomutt', 'clayer', 'textstyle')
        _(vars).must_be_kind_of(Array)
        _(vars.size).must_equal 3
      end

      it 'can accept an array of variable names' do
        vars = drawing.get_variables(%w[nomutt clayer textstyle])
        _(vars).must_be_kind_of(Array)
        _(vars.size).must_equal 3
      end
    end

    describe '#set_variables' do
      it 'sets system variables' do
        names = %w[nomutt clayer textstyle]
        values = drawing.get_variables(names)
        
        # Use different values to ensure the test passes
        test_values = values[0] == 0 ? [1, '0', 'STANDARD'] : [0, '0', 'STANDARD']
        drawing.set_variables(names, test_values)
        values2 = drawing.get_variables(names)

        _(values).wont_equal(values2)
        _(values2).must_equal(test_values)
        drawing.set_variables(names, values)
      end
    end

    describe '#linetypes' do
      it 'returns an enumerator when no block given' do
        _(drawing.linetypes).must_be_kind_of(Enumerator)
      end

      it 'yields linetypes when block given' do
        types = []
        drawing.linetypes { |lt| types << lt }
        _(types).wont_be_empty
        types.each do |lt|
          _(lt).must_be_kind_of(Autocad::Linetype)
        end
      end
    end

    describe '#layouts' do
      it 'returns an enumerator when no block given' do
        _(drawing.layouts).must_be_kind_of(Enumerator)
      end

      it 'yields layouts when block given' do
        layouts = []
        drawing.layouts { |lt| layouts << lt }
        _(layouts).wont_be_empty
        layouts.each do |lt|
          _(lt).must_be_kind_of(Autocad::Layout)
        end
      end
    end

    describe '#plot_configurations' do
      it 'returns an enumerator when no block given' do
        _(drawing.plot_configurations).must_be_kind_of(Enumerator)
      end

      it 'yields PlotConfigurations when block given' do
        configs = []
        drawing.plot_configurations { |lt| configs << lt }
        _(configs).wont_be_empty
        configs.each do |lt|
          _(lt).must_be_kind_of(Autocad::PlotConfiguration)
        end
      end
    end

    describe '#layers' do
      it 'returns an enumerator when no block given' do
        _(drawing.layers).must_be_kind_of(Enumerator)
      end

      it 'yields layers when block given' do
        layers = []
        drawing.layers { |layer| layers << layer }
        _(layers).wont_be_empty
        layers.each do |layer|
          _(layer).must_be_kind_of(Autocad::Layer)
        end
      end
    end

    describe '#create_layer' do
      it 'creates a new layer' do
        layer_name = 'TestLayer'
        layer = drawing.create_layer(layer_name)
        _(layer).must_be_kind_of(Autocad::Layer)
        _(layer.name).must_equal layer_name
      end

      it 'returns existing layer if it already exists' do
        layer_name = 'TestLayer2'
        layer1 = drawing.create_layer(layer_name)
        layer2 = drawing.create_layer(layer_name)
        _(layer2).must_be_kind_of(Autocad::Layer)
        _(layer2.name).must_equal layer_name
      end

      it 'sets color if provided' do
        layer_name = 'ColoredLayer'
        color = 1 # Red
        layer = drawing.create_layer(layer_name, color)
        _(layer.color).must_equal color
      end
    end

    describe '#active_layer' do
      it 'returns the active layer' do
        layer = drawing.active_layer
        _(layer).must_be_kind_of(Autocad::Layer)
      end

      it 'can set the active layer by name' do
        layer_name = 'NewActiveLayer'
        drawing.create_layer(layer_name)
        drawing.active_layer = layer_name
        _(drawing.active_layer_name).must_equal layer_name
      end

      it 'can set the active layer by object' do
        layer_name = 'AnotherActiveLayer'
        layer = drawing.create_layer(layer_name)
        drawing.active_layer = layer
        _(drawing.active_layer_name).must_equal layer_name
      end
    end

    describe '#model_space and #paper_space' do
      it 'returns the model space' do
        model = drawing.model_space
        _(model).must_be_kind_of(Autocad::ModelSpace)
      end

      it 'returns the paper space' do
        paper = drawing.paper_space
        _(paper).must_be_kind_of(Autocad::PaperSpace)
      end

      it 'has aliases for model and paper' do
        _(drawing.model).must_equal drawing.model_space
        _(drawing.paper).must_equal drawing.paper_space
      end
    end

    describe '#to_model_space and #to_paper_space' do
      it 'switches to model space' do
        drawing.to_model_space
        _(drawing.model_space?).must_equal true
        _(drawing.paper_space?).must_equal false
      end

      it 'switches to paper space' do
        drawing.to_paper_space
        _(drawing.paper_space?).must_equal true
        _(drawing.model_space?).must_equal false
      end
    end

    describe '#pdf_plot_config' do
      it 'creates a PDF plot configuration' do
        config = drawing.pdf_plot_config
        _(config).must_be_kind_of(Autocad::PlotConfiguration)
        _(config.name).must_equal 'faa_ansid_bw'
      end
    end

    describe '#paper_space_layout' do
      it 'returns the first non-Model layout' do
        layout = drawing.paper_space_layout
        _(layout).must_be_kind_of(Autocad::Layout)
        _(layout.name).wont_equal 'Model'
      end
    end

    describe '#blocks' do
      it 'returns an enumerator when no block given' do
        _(drawing.blocks).must_be_kind_of(Enumerator)
      end

      it 'yields blocks when block given' do
        blocks = []
        drawing.blocks { |block| blocks << block }
        blocks.each do |block|
          _(block).must_be_kind_of(Autocad::Block)
        end
      end
    end

    describe '#event_handler' do
      it 'returns an event handler' do
        handler = drawing.event_handler
        _(handler).must_be_kind_of(Autocad::EventHandler)
      end
    end

    describe '#register_handler' do
      it 'adds a handler for an event' do
        called = false
        drawing.register_handler('BeginSave') { called = true }
        # We can't easily test if it's called, but we can check it doesn't error
        _(called).must_equal false
      end
    end

    describe '#regen' do
      it 'regenerates the drawing' do
        # This is mostly a smoke test to ensure it doesn't error
        drawing.regen
        drawing.regen(:active)
        pass
      end
    end

    describe '#name and #path' do
      it 'returns the drawing name' do
        _(drawing.name).must_equal 'test.dwg'
      end

      it 'returns the drawing path' do
        _(drawing.path.to_s).must_match(/test\.dwg$/)
      end

      it 'returns the drawing basename' do
        _(drawing.basename.to_s).must_equal 'test.dwg'
      end

      it 'returns the drawing dirname' do
        _(drawing.dirname).must_be_kind_of(Pathname)
      end
    end

    describe '#save' do
      it 'saves the drawing' do
        # This is mostly a smoke test
        drawing.save
        pass
      end

      it 'saves the drawing with a new name' do
        new_name = "test_new_name_#{Time.now.to_i}.dwg"
        drawing.save(name: new_name)
        new_path = drawing.dirname + new_name
        _(File.exist?(new_path)).must_equal true
        @temp_files << new_path # Track for cleanup
      end
    end

    describe '#close' do
      it 'closes the drawing' do
        temp_name = "temp_test_#{Time.now.to_i}.dwg"
        temp_drawing = @app.new_drawing(temp_name)
        @temp_files << temp_drawing.path # Track for cleanup
        temp_drawing.close(false)
        # Test it's closed by checking if we can access a property
        assert_raises(StandardError) { temp_drawing.name }
      end
    end
  end
end
