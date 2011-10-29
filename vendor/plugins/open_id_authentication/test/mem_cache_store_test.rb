#-- encoding: UTF-8
require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/open_id_authentication/mem_cache_store'

# Mock MemCacheStore with MemoryStore for testing
class OpenIdAuthentication::MemCacheStore < OpenID::Store::Interface
  def initialize(*addresses)
    @connection = ActiveSupport::Cache::MemoryStore.new
  end
end

class MemCacheStoreTest < Test::Unit::TestCase
  ALLOWED_HANDLE = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'

  def setup
    @store = OpenIdAuthentication::MemCacheStore.new
  end

  def test_store
    server_url = "http://www.myopenid.com/openid"
    assoc = gen_assoc(0)

    # Make sure that a missing association returns no result
    assert_retrieve(server_url)

    # Check that after storage, getting returns the same result
    @store.store_association(server_url, assoc)
    assert_retrieve(server_url, nil, assoc)

    # more than once
    assert_retrieve(server_url, nil, assoc)

    # Storing more than once has no ill effect
    @store.store_association(server_url, assoc)
    assert_retrieve(server_url, nil, assoc)

    # Removing an association that does not exist returns not present
    assert_remove(server_url, assoc.handle + 'x', false)

    # Removing an association that does not exist returns not present
    assert_remove(server_url + 'x', assoc.handle, false)

    # Removing an association that is present returns present
    assert_remove(server_url, assoc.handle, true)

    # but not present on subsequent calls
    assert_remove(server_url, assoc.handle, false)

    # Put assoc back in the store
    @store.store_association(server_url, assoc)

    # More recent and expires after assoc
    assoc2 = gen_assoc(1)
    @store.store_association(server_url, assoc2)

    # After storing an association with a different handle, but the
    # same server_url, the handle with the later expiration is returned.
    assert_retrieve(server_url, nil, assoc2)

    # We can still retrieve the older association
    assert_retrieve(server_url, assoc.handle, assoc)

    # Plus we can retrieve the association with the later expiration
    # explicitly
    assert_retrieve(server_url, assoc2.handle, assoc2)

    # More recent, and expires earlier than assoc2 or assoc. Make sure
    # that we're picking the one with the latest issued date and not
    # taking into account the expiration.
    assoc3 = gen_assoc(2, 100)
    @store.store_association(server_url, assoc3)

    assert_retrieve(server_url, nil, assoc3)
    assert_retrieve(server_url, assoc.handle, assoc)
    assert_retrieve(server_url, assoc2.handle, assoc2)
    assert_retrieve(server_url, assoc3.handle, assoc3)

    assert_remove(server_url, assoc2.handle, true)

    assert_retrieve(server_url, nil, assoc3)
    assert_retrieve(server_url, assoc.handle, assoc)
    assert_retrieve(server_url, assoc2.handle, nil)
    assert_retrieve(server_url, assoc3.handle, assoc3)

    assert_remove(server_url, assoc2.handle, false)
    assert_remove(server_url, assoc3.handle, true)

    assert_retrieve(server_url, nil, assoc)
    assert_retrieve(server_url, assoc.handle, assoc)
    assert_retrieve(server_url, assoc2.handle, nil)
    assert_retrieve(server_url, assoc3.handle, nil)

    assert_remove(server_url, assoc2.handle, false)
    assert_remove(server_url, assoc.handle, true)
    assert_remove(server_url, assoc3.handle, false)

    assert_retrieve(server_url, nil, nil)
    assert_retrieve(server_url, assoc.handle, nil)
    assert_retrieve(server_url, assoc2.handle, nil)
    assert_retrieve(server_url, assoc3.handle, nil)

    assert_remove(server_url, assoc2.handle, false)
    assert_remove(server_url, assoc.handle, false)
    assert_remove(server_url, assoc3.handle, false)
  end

  def test_nonce
    server_url = "http://www.myopenid.com/openid"

    [server_url, ''].each do |url|
      nonce1 = OpenID::Nonce::mk_nonce

      assert_nonce(nonce1, true, url, "#{url}: nonce allowed by default")
      assert_nonce(nonce1, false, url, "#{url}: nonce not allowed twice")
      assert_nonce(nonce1, false, url, "#{url}: nonce not allowed third time")

      # old nonces shouldn't pass
      old_nonce = OpenID::Nonce::mk_nonce(3600)
      assert_nonce(old_nonce, false, url, "Old nonce #{old_nonce.inspect} passed")
    end
  end

  private
    def gen_assoc(issued, lifetime = 600)
      secret = OpenID::CryptUtil.random_string(20, nil)
      handle = OpenID::CryptUtil.random_string(128, ALLOWED_HANDLE)
      OpenID::Association.new(handle, secret, Time.now + issued, lifetime, 'HMAC-SHA1')
    end

    def assert_retrieve(url, handle = nil, expected = nil)
      assoc = @store.get_association(url, handle)

      if expected.nil?
        assert_nil(assoc)
      else
        assert_equal(expected, assoc)
        assert_equal(expected.handle, assoc.handle)
        assert_equal(expected.secret, assoc.secret)
      end
    end

    def assert_remove(url, handle, expected)
      present = @store.remove_association(url, handle)
      assert_equal(expected, present)
    end

    def assert_nonce(nonce, expected, server_url, msg = "")
      stamp, salt = OpenID::Nonce::split_nonce(nonce)
      actual = @store.use_nonce(server_url, stamp, salt)
      assert_equal(expected, actual, msg)
    end
end
