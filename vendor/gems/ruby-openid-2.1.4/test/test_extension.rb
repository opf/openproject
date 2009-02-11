require 'openid/extension'
require 'openid/message'
require 'test/unit'

module OpenID
  class DummyExtension < OpenID::Extension
    TEST_URI = 'http://an.extension'
    TEST_ALIAS = 'dummy'
    def initialize
      @ns_uri = TEST_URI
      @ns_alias = TEST_ALIAS
    end

    def get_extension_args
      return {}
    end
  end

  class ToMessageTest < Test::Unit::TestCase
     def test_OpenID1
       oid1_msg = Message.new(OPENID1_NS)
       ext = DummyExtension.new
       ext.to_message(oid1_msg)
       namespaces = oid1_msg.namespaces
       assert(namespaces.implicit?(DummyExtension::TEST_URI))
       assert_equal(
                    DummyExtension::TEST_URI,
                    namespaces.get_namespace_uri(DummyExtension::TEST_ALIAS))
       assert_equal(DummyExtension::TEST_ALIAS,
                    namespaces.get_alias(DummyExtension::TEST_URI))
     end
 
     def test_OpenID2
       oid2_msg = Message.new(OPENID2_NS)
       ext = DummyExtension.new
       ext.to_message(oid2_msg)
       namespaces = oid2_msg.namespaces
       assert(!namespaces.implicit?(DummyExtension::TEST_URI))
       assert_equal(
             DummyExtension::TEST_URI,
             namespaces.get_namespace_uri(DummyExtension::TEST_ALIAS))
       assert_equal(DummyExtension::TEST_ALIAS,
                    namespaces.get_alias(DummyExtension::TEST_URI))
     end
   end
end
