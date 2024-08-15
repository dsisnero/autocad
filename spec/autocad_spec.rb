require_relative "spec_helper"

describe Autocad do
  describe "#root" do
    subject { Autocad.root }

    it "should return a pathname" do
      _(subject).must_be_instance_of(Pathname)
    end

    it "should have lib as a child" do
      _(subject.children.map(&:basename)).must_include(Pathname("lib"))
    end
  end

  describe "#run" do
    result = nil
    Autocad.run do |app|
      _(app).must_be_instance_of(Autocad::App)
      result = app
      _(result).must_be_instance_of(Autocad::App)
    end
  end
end
