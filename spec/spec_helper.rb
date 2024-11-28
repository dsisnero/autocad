# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../exe", __dir__)
require "autocad"
require "pw_print"

require "minitest/autorun"
require "minitest/spec"
require "minitest/mock"
require "pathname"
require "tmpdir"
