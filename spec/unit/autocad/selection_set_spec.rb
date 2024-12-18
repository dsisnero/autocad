require_relative "../../spec_helper"

describe Autocad::SelectionSet do
  include TestHelper
  let(:path) { "ss_drawing.dwg" }

  before(:all) do
    @app = Autocad::App.new
    @drawing = create_new_drawing(path)
  end

  after(:all) do
    @drawing.close if @drawing
    @app.quit
    cleanup_test_drawing(path)
  end

  describe "new selection_set" do
    let(:ss) { @drawing.create_selection_set("test_ss") }

    it "has a name" do
      _(ss.name).must_equal "test_ss"
    end

    describe "#filter" do
      it "has a filter method" do
        skip
        filter = ss.filter do |f|
          f.type("Circle").or(f.type("Arc"))
        end
        _(filter.filter_types).must_equal([-4, 0, 0, -4])
        _(filter.filter_values).must_equal(["<OR", "Circle", "Arc", "OR>"])
      end

      it "can filter text" do
        filter = ss.filter_text("*The*")
        _(filter.filter_types).must_equal([-4, 0, 0, -4])
        _(filter.filter_values).must_equal(["<OR", "TEXT", "MTEXT", "OR>"])
      end

      it "can filter block reference" do
        filter = ss.filter do |f|
          f.block_reference
        end
        _(filter.filter_types).must_equal([0])
        _(filter.filter_values).must_equal(["INSERT"])
      end

      it "has a not operator" do
        skip
        ss.filter do |f|
          f.not(
            f.type("Circle").or(f.type("Arc"))
          )
        end
        _(filter.filter_types).must_equal([-4, -4, 0, 0, -4, -4])
        _(filter.filter_values).must_equal(["<NOT", "<OR", "Circle", "Arc", "OR>", "NOT>"])
      end
    end
  end
end
