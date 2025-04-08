# frozen_string_literal: true

require 'optparse_plus/test/base_integration_test'

class TestSomething < OptparsePlus::BaseIntegrationTest
  def test_truth
    stdout, _, _ = run_app('pw_print', '--help')
    assert_banner(stdout, 'pw_print', takes_options: true, takes_arguments: true)
    assert_option(stdout, '-h', '--help')
    assert_option(stdout, '--version')
    assert_option(stdout, '-d DIR', '--save-dir')
    assert_oneline_summary(stdout)
  end
end
