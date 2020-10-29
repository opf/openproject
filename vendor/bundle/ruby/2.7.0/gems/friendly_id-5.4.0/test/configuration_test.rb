require "helper"

class ConfigurationTest < TestCaseClass

  include FriendlyId::Test

  def setup
    @model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
    end
  end

  test "should set model class on initialization" do
    config = FriendlyId::Configuration.new @model_class
    assert_equal @model_class, config.model_class
  end

  test "should set options on initialization if present" do
    config = FriendlyId::Configuration.new @model_class, :base => "hello"
    assert_equal "hello", config.base
  end

  test "should raise error if passed unrecognized option" do
    assert_raises NoMethodError do
      FriendlyId::Configuration.new @model_class, :foo => "bar"
    end
  end

  test "#use should accept a name that resolves to a module" do
    refute @model_class < FriendlyId::Slugged
    @model_class.class_eval do
      extend FriendlyId
      friendly_id :hello, :use => :slugged
    end
    assert @model_class < FriendlyId::Slugged
  end

  test "#use should accept a module" do
    my_module = Module.new
    refute @model_class < my_module
    @model_class.class_eval do
      extend FriendlyId
      friendly_id :hello, :use => my_module
    end
    assert @model_class < my_module
  end

  test "#base should optionally set a value" do
    config = FriendlyId::Configuration.new @model_class
    assert_nil config.base
    config.base = 'foo'
    assert_equal 'foo', config.base
  end

  test "#base can set the value to nil" do
    config = FriendlyId::Configuration.new @model_class
    config.base 'foo'
    config.base nil
    assert_nil config.base

  end


end
