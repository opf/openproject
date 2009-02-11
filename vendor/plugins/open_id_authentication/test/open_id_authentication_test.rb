require File.dirname(__FILE__) + '/test_helper'

class OpenIdAuthenticationTest < Test::Unit::TestCase
  def setup
    @controller = Class.new do
      include OpenIdAuthentication
      def params() {} end
    end.new
  end

  def test_authentication_should_fail_when_the_identity_server_is_missing
    open_id_consumer = mock()
    open_id_consumer.expects(:begin).raises(OpenID::OpenIDError)
    @controller.expects(:open_id_consumer).returns(open_id_consumer)
    @controller.expects(:logger).returns(mock(:error => true))

    @controller.send(:authenticate_with_open_id, "http://someone.example.com") do |result, identity_url|
      assert result.missing?
      assert_equal "Sorry, the OpenID server couldn't be found", result.message
    end
  end

  def test_authentication_should_be_invalid_when_the_identity_url_is_invalid
    @controller.send(:authenticate_with_open_id, "!") do |result, identity_url|
      assert result.invalid?, "Result expected to be invalid but was not"
      assert_equal "Sorry, but this does not appear to be a valid OpenID", result.message
    end
  end

  def test_authentication_should_fail_when_the_identity_server_times_out
    open_id_consumer = mock()
    open_id_consumer.expects(:begin).raises(Timeout::Error, "Identity Server took too long.")
    @controller.expects(:open_id_consumer).returns(open_id_consumer)
    @controller.expects(:logger).returns(mock(:error => true))

    @controller.send(:authenticate_with_open_id, "http://someone.example.com") do |result, identity_url|
      assert result.missing?
      assert_equal "Sorry, the OpenID server couldn't be found", result.message
    end
  end

  def test_authentication_should_begin_when_the_identity_server_is_present
    @controller.expects(:begin_open_id_authentication)
    @controller.send(:authenticate_with_open_id, "http://someone.example.com")
  end
end
