##
# Add circuit breakers for CI builds, such as focused specs
# that somehow elude linting
RSpec.configure do |config|
  if ENV["CI"]
    config.before(:example, :focus) { |example| raise "Found focused example at #{example.location}" }
  else
    # This allows you to limit a spec run to individual examples or groups
    # you care about by tagging them with `:focus` metadata. When nothing
    # is tagged with `:focus`, all examples get run. RSpec also provides
    # aliases for `it`, `describe`, and `context` that include `:focus`
    # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
    config.filter_run_when_matching :focus
  end
end
