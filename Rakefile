# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'

Minitest::TestTask.create

Minitest::TestTask.create :unit do |t|
  t.test_globs = ['spec/unit/**/*_spec.rb']
  t.warning = false
end

require 'standard/rake'

task default: %i[test standard]
