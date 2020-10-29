# to use:
# require "test/test_helper"
# bundle exec ruby test/auto_strip_attributes_test.rb -v --name /test_name/

require 'minitest/autorun'
require 'minitest/spec'
require "active_record"
require "auto_strip_attributes"
require 'mocha/setup'

# if you need debug, add relevant line to auto_strip_attributes.gemspec
# s.add_development_dependency 'pry'
# and uncomment following line, and then write binding.pry somewhere
# require 'pry'


class MockRecordParent
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  extend AutoStripAttributes

  # Overriding @record[key]=val , that's only found in activerecord, not in ActiveModel
  def []=(key, val)
    # send("#{key}=", val)  # We dont want to call setter again
    instance_variable_set(:"@#{key}", val)
  end

  def [](key)
    k = :"@#{key}"
    instance_variable_defined?(k) ? instance_variable_get(k) : nil
  end

end

describe AutoStripAttributes do

  def setup
    @init_params = {:foo => "\tfoo  ", :bar => " bar  bar "}
  end

  def teardown
    AutoStripAttributes::Config.filters = {}
    AutoStripAttributes::Config.filters_enabled = {}
    AutoStripAttributes::Config.filters_order = []
    AutoStripAttributes::Config.setup
  end

  it "should have defined AutoStripAttributes" do
    assert Object.const_defined?(:AutoStripAttributes)
  end

  describe "Basic attribute with default options and conditional evaluation" do
    class MockRecordBasic < MockRecordParent
      attr_accessor :boo
      auto_strip_attributes :boo, if: ->(record) { record[:boo] == " bbb \t" }
    end

    it "should not strip when conditional is not met" do
      @record = MockRecordBasic.new()
      @record.boo = " aaa \t"
      @record.valid?
      @record.boo.must_equal " aaa \t"
    end

    it "should strip when conditional is met" do
      @record = MockRecordBasic.new()
      @record.boo = " bbb \t"
      @record.valid?
      @record.boo.must_equal "bbb"
    end
  end

  describe "Basic attribute with default options" do
    class MockRecordBasic < MockRecordParent
      attr_accessor :foo
      auto_strip_attributes :foo
    end

    it "should be ok for normal strings" do
      @record = MockRecordBasic.new()
      @record.foo = " aaa \t"
      @record.valid?
      @record.foo.must_equal "aaa"
    end

    it "should be ok for strings arrays" do
      @record = MockRecordBasic.new()
      @record.foo = [" aaa \t", " "]
      @record.valid?
      @record.foo.must_equal ["aaa"]
    end

    it "should not delete non breaking spaces" do
      @record = MockRecordBasic.new()
      @record.foo = " aaa \t\u00A0"
      @record.valid?
      @record.foo.must_equal "aaa \t\u00A0"
    end

    it "should be ok for normal strings and not squish things" do
      @record = MockRecordBasic.new()
      @record.foo = " aaa  bbb  "
      @record.valid?
      @record.foo.must_equal "aaa  bbb"
    end


    it "should set empty strings to nil" do
      @record = MockRecordBasic.new()
      @record.foo = " "
      @record.valid?
      @record.foo.must_be_nil
    end

    it "should set empty strings arrays to nil" do
      @record = MockRecordBasic.new()
      @record.foo = [" "]
      @record.valid?
      @record.foo.must_be_nil
    end

    it "should call strip method to attribute if possible" do
      @record = MockRecordBasic.new()
      str_mock = "  strippable_str  "
      str_mock.expects(:strip).returns(@stripped_str="stripped_str_here")
      @record.foo = str_mock
      @record.valid?
      assert true
      @record.foo.must_be_same_as @stripped_str

      #str_mock.expect :'nil?', false
      #str_mock.expect :strip, (@stripped_str="stripped_str_here")
      #@record.foo = str_mock
      #@record.valid?
      #str_mock.verify
      #@record.foo.must_be_same_as @stripped_str
    end

    it "should not call strip or nullify method for non strippable attributes" do
      @record = MockRecordBasic.new()

      str_mock = MiniTest::Mock.new() # answers false to str_mock.respond_to?(:strip) and respond_to?(:blank)
      # Mock.new is problematic in ruby 1.9 because it responds to blank? but doesn't respond to !
      # rails blank? method returns !self if an object doesn't respond to :empty?
      # Now we check in the validator also for :empty? so !self is never called.
      # Other way could be to mock !self in here

      @record.foo = str_mock
      @record.valid?
      assert @record.foo === str_mock
      str_mock.verify # "Should not call anything on mock when respond_to is false"
    end
  end

  describe "Attribute with convert non breaking spaces option" do
    #class MockRecordWithConvertNBSP < ActiveRecord::Base
    class MockRecordWithConvertNBSP < MockRecordParent
      #column :foo, :string
      attr_accessor :foo
      auto_strip_attributes :foo, convert_non_breaking_spaces: true
    end

    it "should delete non breaking spaces" do
      @record = MockRecordWithConvertNBSP.new()
      @record.foo = " aaa \t\u00A0"
      @record.valid?
      @record.foo.must_equal "aaa"
    end

  end

  describe "Attribute with nullify option" do
    #class MockRecordWithNullify < ActiveRecord::Base
    class MockRecordWithNullify < MockRecordParent
      #column :foo, :string
      attr_accessor :foo
      auto_strip_attributes :foo, nullify: false
    end

    it "should not set blank strings to nil" do
      @record = MockRecordWithNullify.new
      @record.foo = "  "
      @record.valid?
      @record.foo.must_equal ""
    end

    it "should not set blank strings arrays to nil" do
      @record = MockRecordWithNullify.new()
      @record.foo = [" "]
      @record.valid?
      @record.foo.must_equal [""]
    end
  end

  describe "Attribute with nullify_array option" do
    #class MockRecordWithNullifyArray < ActiveRecord::Base
    class MockRecordWithNullifyArray < MockRecordParent
      #column :foo, :string
      attr_accessor :foo
      auto_strip_attributes :foo, nullify_array: false
    end

    it "should not set blank strings array to nil" do
      @record = MockRecordWithNullifyArray.new
      @record.foo = ["  "]
      @record.valid?
      @record.foo.must_equal []
    end
  end

  describe "Attribute with squish option" do
    class MockRecordWithSqueeze < MockRecordParent #< ActiveRecord::Base
      attr_accessor :foo
      # testing also that `:squish => true` implies `:strip => true`
      auto_strip_attributes :foo, squish: true, strip: false
    end

    it "should squish string also form inside" do
      @record = MockRecordWithSqueeze.new
      @record.foo = "  aaa \u0009 \u000A \u000B \u000C \u000D \u0020 \u0085 \u00A0 \u1680 \u2000 \u2001 \u2002 \u2003 \u2004 \u2005 \u2006 \u2007 \u2008 \u2009 \u200A \u2028 \u2029 \u202F \u205F \u3000 bbb  \u00A0   "
      @record.valid?
      @record.foo.must_equal "aaa bbb"
    end

    it "should do normal nullify with empty string" do
      @record = MockRecordWithSqueeze.new
      @record.foo = "  "
      @record.valid?
      @record.foo.must_be_nil
    end
  end

  describe "Attribute with delete_whitespaces option" do
    class MockRecordWithDelete < MockRecordParent
      #column :foo, :string
      attr_accessor :foo
      auto_strip_attributes :foo, delete_whitespaces: true
    end

    it "should delete all spaces and tabs" do
      @record = MockRecordWithDelete.new
      @record.foo = " a \t  bbb"
      @record.valid?
      @record.foo.must_equal "abbb"
    end
  end

  describe "Multible attributes with multiple options" do
    class MockRecordWithMultipleAttributes < MockRecordParent #< ActiveRecord::Base
      #column :foo, :string
      #column :bar, :string
      #column :baz, :string
      #column :qux, :string, array: true
      #column :quux, :string, array: true
      #column :quuz, :string, array: true
      attr_accessor :foo, :bar, :baz, :qux, :quux, :quuz
      auto_strip_attributes :foo, :bar, :qux
      auto_strip_attributes :baz, :quux, {nullify: false, squish: true}
      auto_strip_attributes :quuz, {nullify: true, nullify_array: false}
    end

    it "should handle everything ok" do
      @record = MockRecordWithMultipleAttributes.new
      @record.foo = "  foo\tfoo"
      @record.bar = "  "
      @record.baz = "  "
      @record.qux = ["\n"]
      @record.quux = ["  foo\tfoo", "  "]
      @record.quuz = [" "]
      @record.valid?
      @record.foo.must_equal "foo\tfoo"
      @record.bar.must_be_nil
      @record.baz.must_equal ""
      @record.qux.must_be_nil
      @record.quux.must_equal ["foo foo", ""]
      @record.quuz.must_equal []
    end
  end

  describe "Attribute with custom setter" do
    class MockRecordWithCustomSetter < MockRecordParent # < ActiveRecord::Base
      #column :foo, :string
      attr_accessor :foo
      auto_strip_attributes :foo

      def foo=(val)
        self[:foo] = "#{val}-#{val}"
      end
    end

    it "should not call setter again in before_validation" do
      @record = MockRecordWithCustomSetter.new
      @record.foo = " foo "
      @record.foo.must_equal " foo - foo "
      @record.valid?
      @record.foo.must_equal "foo - foo"
    end
  end

  describe "Virtual attributes" do
    class MockVirtualAttribute < MockRecordParent
      undef :[]=
      undef :[]

      auto_strip_attributes :foo, virtual: true

      def foo
        @bar
      end

      def foo=(val)
        @bar = val
      end
    end

    it "should handle everything ok" do
      @record = MockVirtualAttribute.new
      @record.foo = "  foo  "
      @record.foo.must_equal "  foo  "
      @record.valid?
      @record.foo.must_equal "foo"
    end
  end

  describe "Configuration tests" do
    it "should have defined AutoStripAttributes::Config" do
      assert AutoStripAttributes.const_defined?(:Config)
    end

    it "should have default filters set in right order" do
      AutoStripAttributes::Config.setup(clear_previous: true)
      filters_order = AutoStripAttributes::Config.filters_order
      filters_order.must_equal [:convert_non_breaking_spaces, :strip, :nullify, :nullify_array, :squish, :delete_whitespaces]
    end

    it "should reset filters to defaults when :clear is true" do
      AutoStripAttributes::Config.setup do
        set_filter(:test) do
          'test'
        end
      end
      AutoStripAttributes::Config.setup(clear_previous: true)
      filters_order = AutoStripAttributes::Config.filters_order
      filters_order.must_equal [:convert_non_breaking_spaces, :strip, :nullify, :nullify_array, :squish, :delete_whitespaces]
    end

    it "should remove all filters when :clear is true and :defaults is false" do
      AutoStripAttributes::Config.setup do
        set_filter(:test) do
          'test'
        end
      end
      AutoStripAttributes::Config.setup(clear_previous: true, defaults: false)
      filter_order = AutoStripAttributes::Config.filters_order
      filter_order.must_equal []

      # returning to original state
      AutoStripAttributes::Config.setup(clear_previous: true)
    end

    it "should correctly define and process custom filters" do
      class MockRecordWithCustomFilter < MockRecordParent #< ActiveRecord::Base
        attr_accessor :foo
        auto_strip_attributes :foo
      end

      AutoStripAttributes::Config.setup do
        set_filter(test: true) do |value|
          value.downcase
        end
      end

      filters_block = AutoStripAttributes::Config.filters
      filters_order = AutoStripAttributes::Config.filters_order
      filters_enabled = AutoStripAttributes::Config.filters_enabled

      filters_order.must_equal [:convert_non_breaking_spaces, :strip, :nullify, :nullify_array, :squish, :delete_whitespaces, :test]
      assert Proc === filters_block[:test]
      filters_enabled[:test].must_equal true

      @record = MockRecordWithCustomFilter.new
      @record.foo = " FOO "
      @record.valid?
      @record.foo.must_equal "foo"

      # returning to original state
      AutoStripAttributes::Config.setup(clear_previous: true)
    end

  end

  describe "Using options in custom filters" do
    class CustomOptionsMockRecord < MockRecordParent
      attr_accessor :foo, :bar_downcase
      auto_strip_attributes :foo, truncate_test: {length: 5, separator: " ", omission: "…"}
    end

    def setup
      AutoStripAttributes::Config.setup do
        set_filter(:truncate_test) do |value, options|
          !value.blank? && value.respond_to?(:truncate) ? value.truncate(options[:length], omission: options[:omission]) : value
        end
      end
    end

    def teardown
      AutoStripAttributes::Config.setup(defaults: true, clear_previous: true)
    end

    it "should be able to truncate as asked" do
      @record = CustomOptionsMockRecord.new
      @record.foo = " abcdefghijklmnopqrstijklmn"
      @record.valid?
      @record.foo.must_equal "abcd…"
    end
  end

  describe "complex usecase with custom config" do
    class ComplexFirstMockRecord < MockRecordParent
      #column :foo, :string
      attr_accessor :foo, :bar_downcase
      auto_strip_attributes :foo
      auto_strip_attributes :bar_downcase, downcase: true, nullify: false
    end

    # before will not work currently: https://github.com/seattlerb/minitest/issues/50 using def setup
    #before do
    #end

    def setup
      AutoStripAttributes::Config.setup do
        set_filter(downcase: false) do |value|
          value.downcase if value.respond_to?(:downcase)
        end
      end
    end

    def teardown
      AutoStripAttributes::Config.setup(defaults: true, clear_previous: true)
    end

    it "should not use extra filters when not in setup" do
      @record = ComplexFirstMockRecord.new
      @record.foo = " FOO "
      @record.valid?
      @record.foo.must_equal "FOO"
    end

    it "should use extra filters when given" do
      @record = ComplexFirstMockRecord.new
      @record.bar_downcase = " BAR "
      @record.valid?
      @record.bar_downcase.must_equal "bar"
    end

    it "should use extra filters when given and also respect given other configs" do
      @record = ComplexFirstMockRecord.new
      @record.bar_downcase = "    "
      @record.valid?
      @record.bar_downcase.must_equal ""
    end
  end


end
