# The following aliases are defined so that we can write
# `expect_it { to match /rgx/ }` instead of
# `it { should match /rgx/ }` to be more consistent with the new expect syntax.

RSpec.configure do |c|
  c.alias_example_to :expect_it
end

RSpec::Core::MemoizedHelpers.module_eval do
  alias to should
  alias to_not should_not
end
