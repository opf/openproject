require "helper"

class CoreTest < TestCaseClass
  include FriendlyId::Test

  test "friendly_id can be added using 'extend'" do
    klass = Class.new(ActiveRecord::Base) do
      extend FriendlyId
    end
    assert klass.respond_to? :friendly_id
  end

  test "friendly_id can be added using 'include'" do
    klass = Class.new(ActiveRecord::Base) do
      include FriendlyId
    end
    assert klass.respond_to? :friendly_id
  end

  test "friendly_id should accept a base and a hash" do
    klass = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend FriendlyId
      friendly_id :foo, :use => :slugged, :slug_column => :bar
    end
    assert klass < FriendlyId::Slugged
    assert_equal :foo, klass.friendly_id_config.base
    assert_equal :bar, klass.friendly_id_config.slug_column
  end


  test "friendly_id should accept a block" do
    klass = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend FriendlyId
      friendly_id :foo do |config|
        config.use :slugged
        config.base = :foo
        config.slug_column = :bar
      end
    end
    assert klass < FriendlyId::Slugged
    assert_equal :foo, klass.friendly_id_config.base
    assert_equal :bar, klass.friendly_id_config.slug_column
  end

  test "the block passed to friendly_id should be evaluated before arguments" do
    klass = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend FriendlyId
      friendly_id :foo do |config|
        config.base = :bar
      end
    end
    assert_equal :foo, klass.friendly_id_config.base
  end

  test "should allow defaults to be set via a block" do
    begin
      FriendlyId.defaults do |config|
        config.base = :foo
      end
      klass = Class.new(ActiveRecord::Base) do
        self.abstract_class = true
        extend FriendlyId
      end
      assert_equal :foo, klass.friendly_id_config.base
    ensure
      FriendlyId.instance_variable_set :@defaults, nil
    end
  end
end
