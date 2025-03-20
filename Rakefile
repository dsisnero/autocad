# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'

Minitest::TestTask.create

Minitest::TestTask.create :unit do |t|
  t.test_globs = ['spec/unit/**/*_spec.rb']
  t.warning = false
end

# Create a namespace for test tasks
namespace :test do
  desc "Run unit tests"
  task :unit => :unit

  desc "Run specific drawing test"
  task :drawing_set_variables do
    sh "ruby -Ilib:spec spec/unit/autocad/drawing_spec.rb --line 117"
  end
end

require 'standard/rake'

task default: %i[test standard]
