require 'test_helper'

require "roar/json/collection"
require "roar/json/hash"

class LonelyCollectionTest < MiniTest::Spec
  it { Roar::JSON::Hash.must_equal Representable::JSON::Hash }
end
