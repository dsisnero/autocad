# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in autocad.gemspec
gemspec

gem "rake", "~> 13.0"

gem "minitest", "~> 5.16"

group :development do
  eval_gemfile "gemfiles/rubocop.gemfile"
end

group :development, :test do
  gem "rbs", require: false
  gem "steep", require: false
  gem "guard-minitest"
  gem "guard-yard"
  gem "rbs-inline"
  gem "debug"
  gem "guard-bundler"
  gem "sord"
end

gem "optparse-plus", "~> 3.0"

gem "webrick", "~> 1.9", groups: [:development, :test]

gem "acrobat", "~> 0.3.0", groups: [:development, :test]

gem "repl_type_completor", "~> 0.1.7", groups: [:development, :test]

gem "fiddle", "~> 1.1"
