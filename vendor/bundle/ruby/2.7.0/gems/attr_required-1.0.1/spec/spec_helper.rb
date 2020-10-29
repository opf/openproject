require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

require 'attr_required'
require 'attr_optional'
require 'rspec'

class A
  include AttrRequired, AttrOptional
  attr_required :attr_required_a
  attr_optional :attr_optional_a
end

class B < A
  attr_required :attr_required_b
  attr_optional :attr_optional_b
end

class C < B
  undef_required_attributes :attr_required_a
  undef_optional_attributes :attr_optional_a
  attr_optional :attr_required_b
  attr_required :attr_optional_b
end

class OnlyRequired
  include AttrRequired
  attr_required :only_required
end

class OnlyOptional
  include AttrOptional
  attr_optional :only_optional
end