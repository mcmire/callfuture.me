
require 'pp'

ENV['RACK_ENV'] = 'test'

require_relative '../vendor/bundler/setup'

require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new

$: << File.expand_path('../../lib', __FILE__)
