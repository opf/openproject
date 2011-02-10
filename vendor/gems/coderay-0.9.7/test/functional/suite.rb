require 'test/unit'

MYDIR = File.dirname(__FILE__)

$:.unshift 'lib'
require 'coderay'
puts "Running basic CodeRay #{CodeRay::VERSION} tests..."

suite = %w(basic load_plugin_scanner word_list)
for test_case in suite
  load File.join(MYDIR, test_case + '.rb')
end
