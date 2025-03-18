# frozen_string_literal: true

require_relative "../../spec_helper"

describe Autocad::App do
  describe "an initialized app" do
    before(:all) do
      @app = Autocad::App.new(visible: true)
    end

    after(:all) do
      @app.quit
    end

    it "doesn't have an active_drawing" do
      _(@app.active_drawing).must_be_nil
    end

    it "allows you to create a drawing" do
      drawing = @app.new_drawing("test.dgn")
      _(drawing).must_be_instance_of(Autocad::Drawing)
      puts drawing.name
      @app.quit
    end

    it "#templates_path returns a pathname" do
      _(@app.templates_path).must_be_instance_of(Pathname)
    end

    it "#templates returns an iterator of templates in template_directory" do
      skip
      templates = @app.templates
      templates.must_be_instance_of ::Enumerator
      templates { |t| puts t }
    end
  end

  describe "App.run" do
    it "call App.new" do
      result = nil
      app = Autocad::App.run do |app|
        _(app).must_be_instance_of(Autocad::App)
        result = app
        _(result).must_be_instance_of(Autocad::App)
      end
    end
  end
end
require_relative "../../spec_helper"

describe Autocad::App do
  describe ".run" do
    it "yields an app instance" do
      called = false
      app_mock = mock('App')
      Autocad::App.stub(:new, app_mock) do
        Autocad::App.run do |app|
          called = true
          _(app).must_equal app_mock
        end
      end
      _(called).must_equal true
    end

    it "handles AutoCAD initialization errors" do
      error_proc_called = false
      error_proc = ->(e, f) { error_proc_called = true }
      
      Autocad::App.any_instance.stubs(:init_ole_and_app_event).raises(RuntimeError)
      
      Autocad::App.run(error_proc: error_proc) { |app| }
      
      _(error_proc_called).must_equal true
    end
  end

  describe "#open_drawing" do
    it "raises error for missing files" do
      with_mocked_autocad do
        app = Autocad::App.new
        
        _(-> {
          app.open_drawing("nonexistent.dwg")
        }).must_raise(Autocad::FileNotFound)
      end
    end
    
    it "yields drawing when block given" do
      with_mocked_autocad do
        with_temp_dir do
          app = Autocad::App.new
          drawing_path = @temp_dir.join("test.dwg")
          create_mock_drawing(drawing_path)
          
          app.stubs(:ole_open_drawing).returns(mock('OleDrawing'))
          app.stubs(:drawing_from_ole).returns(mock('Drawing'))
          app.stubs(:drawing_opened?).returns(true)
          
          drawing_yielded = false
          app.open_drawing(drawing_path) do |drawing|
            drawing_yielded = true
          end
          
          _(drawing_yielded).must_equal true
        end
      end
    end
  end

  describe "#get_point" do
    it "converts base point to OLE variant" do
      with_mocked_autocad do
        app = Autocad::App.new
        
        utility_mock = mock
        doc_ole_mock = mock
        doc_ole_mock.expects(:Utility).returns(utility_mock)
        app.stubs(:doc_ole).returns(doc_ole_mock)
        
        # Mock the WIN32OLE_VARIANT and GetPoint call
        WIN32OLE_VARIANT.expects(:array).returns([0, 0, 0])
        utility_mock.expects(:GetPoint).returns([1, 2, 3])
        
        point = app.get_point(base_point: [10, 20, 30])
        _(point).must_be_instance_of(Autocad::Point3d)
      end
    end
  end
end
