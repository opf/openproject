require 'test_prof/recipes/rspec/any_fixture'
require 'test_prof/ext/active_record_refind'

##
# Shared fixture class, tiny wrapper around TestProf::AnyFixture.
# This will allow to lazily define fixtures through FactoryBot calls
# that are created once and reloaded (instead of recreated) for each example.
class SharedFixture
  # Keep a registry of fixture to instantiate
  # them lazily.
  cattr_accessor :fixtures
  self.fixtures = {}

  # A unique fixture key that we identify dynamic fixtures by
  attr_reader :key, :builder

  def initialize(key, builder)
    @key = key
    @builder = builder
  end

  def self.context_name(key)
    "shared fixture: #{key}"
  end

  ##
  # Create the fixture.
  # This will call the fixture builder.
  def self.create!(key)
    fixture = self.fixtures.fetch key
    ::TestProf::AnyFixture.register(key, &fixture)
  end

  # Reload items that will be a bit slower,
  # but ensure we have a fresh object
  using TestProf::Ext::ActiveRecordRefind

  ##
  # Register a factory as a shared_context
  # with the context_name "shared fixture: <key>"
  # that will bootstrap the Factory once whenever its included.
  def self.register!(key, &block)
    self.fixtures[key] = block

    RSpec.shared_context(self.context_name(key)) do
      before(:all) { ::SharedFixture.create!(key) }
      let(key) { ::TestProf::AnyFixture.register(key).refind }
    end
  end
end

##
# Helper method injected into rspec to load fixtures into self
# Include one or mulitple shared fixture(s)
def using_shared_fixtures(*keys)
  keys.each do |key|
    include_context ::SharedFixture.context_name(key)
  end
end
