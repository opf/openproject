# The Warner class implements a very simple interface. It simply formats
# a warning, so it is more than just the message itself. This default
# warner uses a format comparable to warnings emitted by rb_warn including
# the place where the "thing that caused the warning" resides.
class StructuredWarnings::Warner
  #  Warner.new.format(StructuredWarning::DeprecationWarning, "more info..", caller)
  #     # => "demo.rb:5 : more info.. (StructuredWarning::DeprecationWarning)"
  def format(warning, message, options, stack)
    frame = stack.shift
    # This file contains the backwards compatibility code for Ruby 2.3 and
    # lower, let's skip it
    frame = stack.shift if frame.include? 'lib/structured_warnings/kernel.rb'

    # Handle introduced uplevel introduced in Ruby 2.5
    frame = stack.shift(options[:uplevel]).last if options[:uplevel]

    "#{frame}: #{message} (#{warning})\n"
  end
end
