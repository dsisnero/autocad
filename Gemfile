# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in autocad.gemspec
gemspec

gem 'rake', '~> 13.2'

gem 'minitest', '~> 5.2'

group :development do
  eval_gemfile 'gemfiles/rubocop.gemfile'
end

group :development, :test do
  gem 'debug'
  gem 'guard-bundler'
  gem 'guard-minitest'
  gem 'guard-yard'
  gem 'minitest-bacon'
  gem 'minitest-hooks'
  gem 'rbs', require: false
  gem 'rbs-inline'
  gem 'repl_type_completor'
  gem 'sord'
  gem 'steep', require: false
end

gem 'fiddle'
gem 'optparse-plus', '~> 3.0'

gem 'webrick', '~> 1.9', groups: %i[development test]

gem 'acrobat', '~> 0.3', groups: %i[development test]

gem 'irb'
