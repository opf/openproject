RSpec::Matchers.define :be_boolean do
  match do |value|
    [true, false].include? value
  end
end