# Makes the test suite compatible with Bundler standalone mode (used in CI)
# because Active Record uses `gem` for loading adapters.
Kernel.module_eval do

  remove_method :gem if 'method' == defined? gem

  def gem(*args)
    return if $VERBOSE.nil?
    $stderr << "warning: gem(#{args.map {|o| o.inspect }.join(', ')}) ignored"
    $stderr << "; called from:\n  " << caller[0,5].join("\n  ") if $DEBUG
    $stderr << "\n"
  end

  private :gem

end

$" << "rubygems.rb"
