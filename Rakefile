# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create :test do |t|
  t.libs << "spec"
  t.libs << "lib"
  t.test_globs = ["spec/**/*_spec.rb"]
  t.test_globs -= ["spec/ui/**/*_spec.rb"] # Exclude UI tests from default task
end

Minitest::TestTask.create "test:ui" do |t|
  t.libs << "spec"
  t.libs << "lib"
  t.test_globs = ["spec/ui/**/*_spec.rb"]
end

require "standard/rake"

task default: %i[test standard]
