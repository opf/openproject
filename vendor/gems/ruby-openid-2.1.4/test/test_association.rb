require "test/unit"
require "openid/association"

module OpenID
  class AssociationTestCase < Test::Unit::TestCase
    def setup
      # Use this funny way of getting a time so that it does not have
      # fractional seconds, and so can be serialized exactly using our
      # standard code.
      issued = Time.at(Time.now.to_i)
      lifetime = 600

      @assoc = Association.new('handle', 'secret', issued,
                               lifetime, 'HMAC-SHA1')
    end

    def test_round_trip
      assoc2 = Association.deserialize(@assoc.serialize())
      [:handle, :secret, :lifetime, :assoc_type].each do |attr|
        assert_equal(@assoc.send(attr), assoc2.send(attr))
      end
    end

    def test_deserialize_failure
      field_list = Util.kv_to_seq(@assoc.serialize)
      kv = Util.seq_to_kv(field_list + [['monkeys', 'funny']])
      assert_raises(ProtocolError) {
        Association.deserialize(kv)
      }

      bad_version_list = field_list.dup
      bad_version_list[0] = ['version', 'moon']
      bad_version_kv = Util.seq_to_kv(bad_version_list)
      assert_raises(ProtocolError) {
        Association.deserialize(bad_version_kv)
      }
    end

    def test_serialization_identity
      assoc2 = Association.deserialize(@assoc.serialize)
      assert_equal(@assoc, assoc2)
    end

    def test_expires_in
      # Allow one second of slop
      assert(@assoc.expires_in.between?(599,600))
      assert(@assoc.expires_in(Time.now.to_i).between?(599,600))
      assert_equal(0,@assoc.expires_in(Time.now.to_i + 10000),"negative expires_in")
    end

    def test_from_expires_in
      start_time = Time.now
      expires_in = @assoc.expires_in
      assoc = Association.from_expires_in(expires_in,
                                          @assoc.handle,
                                          @assoc.secret,
                                          @assoc.assoc_type)

      # Allow one second of slop here for code execution time
      assert_in_delta(1, assoc.expires_in, @assoc.expires_in)
      [:handle, :secret, :assoc_type].each do |attr|
        assert_equal(@assoc.send(attr), assoc.send(attr))
      end

      # Make sure the issued time is near the start
      assert(assoc.issued >= start_time)
      assert_in_delta(1, assoc.issued.to_f, start_time.to_f)
    end

    def test_sign_sha1
      pairs = [['key1', 'value1'],
               ['key2', 'value2']]

      [['HMAC-SHA256', "\xfd\xaa\xfe;\xac\xfc*\x988\xad\x05d6-"\
                       "\xeaVy\xd5\xa5Z.<\xa9\xed\x18\x82\\$"\
                       "\x95x\x1c&"],
       ['HMAC-SHA1', "\xe0\x1bv\x04\xf1G\xc0\xbb\x7f\x9a\x8b"\
                     "\xe9\xbc\xee}\\\xe5\xbb7*"],
      ].each do |assoc_type, expected|
        assoc = Association.from_expires_in(3600, "handle", 'very_secret',
                                            assoc_type)
        sig = assoc.sign(pairs)
        assert_equal(sig, expected)

        m = Message.new(OPENID2_NS)
        pairs.each { |k, v|
          m.set_arg(OPENID_NS, k, v)
        }
        m.set_arg(BARE_NS, "not_an_openid_arg", "bogus")

        signed_m = assoc.sign_message(m)
        assert(signed_m.has_key?(OPENID_NS, 'sig'))
        assert_equal(signed_m.get_arg(OPENID_NS, 'signed'),
                     'assoc_handle,key1,key2,ns,signed')
      end
    end

    def test_sign_message_with_sig
      assoc = Association.from_expires_in(3600, "handle", "very_secret",
                                          "HMAC-SHA1")
      m = Message.new(OPENID2_NS)
      m.set_arg(OPENID_NS, 'sig', 'noise')
      assert_raises(ArgumentError) {
        assoc.sign_message(m)
      }
    end

    def test_sign_message_with_signed
      assoc = Association.from_expires_in(3600, "handle", "very_secret",
                                          "HMAC-SHA1")
      m = Message.new(OPENID2_NS)
      m.set_arg(OPENID_NS, 'signed', 'fields')
      assert_raises(ArgumentError) {
        assoc.sign_message(m)
      }
    end

    def test_sign_different_assoc_handle
      assoc = Association.from_expires_in(3600, "handle", "very_secret",
                                          "HMAC-SHA1")
      m = Message.new(OPENID2_NS)
      m.set_arg(OPENID_NS, 'assoc_handle', 'different')
      assert_raises(ArgumentError) {
        assoc.sign_message(m)
      }
    end

    def test_sign_bad_assoc_type
      @assoc.instance_eval { @assoc_type = 'Cookies' }
      assert_raises(ProtocolError) {
        @assoc.sign([])
      }
    end

    def test_make_pairs
      msg = Message.new(OPENID2_NS)
      msg.update_args(OPENID2_NS, {
                        'mode' => 'id_res',
                        'identifier' => '=example',
                        'signed' => 'identifier,mode',
                        'sig' => 'cephalopod',
                      })
      msg.update_args(BARE_NS, {'xey' => 'value'})
      assoc = Association.from_expires_in(3600, '{sha1}', 'very_secret',
                                          "HMAC-SHA1")
      pairs = assoc.make_pairs(msg)
      assert_equal([['identifier', '=example'],
                    ['mode', 'id_res']], pairs)
    end

    def test_check_message_signature_no_signed
      m = Message.new(OPENID2_NS)
      m.update_args(OPENID2_NS, {'mode' => 'id_res',
                      'identifier' => '=example',
                      'sig' => 'coyote',
                    })
      assoc = Association.from_expires_in(3600, '{sha1}', 'very_secret',
                                          "HMAC-SHA1")
      assert_raises(ProtocolError) {
        assoc.check_message_signature(m)
      }
    end

    def test_check_message_signature_no_sig
      m = Message.new(OPENID2_NS)
      m.update_args(OPENID2_NS, {'mode' => 'id_res',
                      'identifier' => '=example',
                      'signed' => 'mode',
                    })
      assoc = Association.from_expires_in(3600, '{sha1}', 'very_secret',
                                          "HMAC-SHA1")
      assert_raises(ProtocolError) {
        assoc.check_message_signature(m)
      }
    end

    def test_check_message_signature_bad_sig
      m = Message.new(OPENID2_NS)
      m.update_args(OPENID2_NS, {'mode' => 'id_res',
                      'identifier' => '=example',
                      'signed' => 'mode',
                      'sig' => Util.to_base64('coyote'),
                    })
      assoc = Association.from_expires_in(3600, '{sha1}', 'very_secret',
                                          "HMAC-SHA1")
      assert(!assoc.check_message_signature(m))
    end

    def test_check_message_signature_good_sig
      m = Message.new(OPENID2_NS)
      m.update_args(OPENID2_NS, {'mode' => 'id_res',
                      'identifier' => '=example',
                      'signed' => 'mode',
                      'sig' => Util.to_base64('coyote'),
                    })
      assoc = Association.from_expires_in(3600, '{sha1}', 'very_secret',
                                          "HMAC-SHA1")
      class << assoc
        # Override sign, because it's already tested elsewhere
        def sign(pairs)
          "coyote"
        end
      end

      assert(assoc.check_message_signature(m))
    end
  end

  class AssociationNegotiatorTestCase < Test::Unit::TestCase
    def assert_equal_under(item1, item2)
      val1 = yield(item1)
      val2 = yield(item2)
      assert_equal(val1, val2)
    end

    def test_copy
      neg = AssociationNegotiator.new([['HMAC-SHA1', 'DH-SHA1']])
      neg2 = neg.copy
      assert_equal_under(neg, neg2) {|n| n.instance_eval{@allowed_types} }
      assert(neg.object_id != neg2.object_id)
    end

    def test_add_allowed
      neg = AssociationNegotiator.new([])
      assert(!neg.allowed?('HMAC-SHA1', 'DH-SHA1'))
      assert(!neg.allowed?('HMAC-SHA1', 'no-encryption'))
      assert(!neg.allowed?('HMAC-SHA256', 'DH-SHA256'))
      assert(!neg.allowed?('HMAC-SHA256', 'no-encryption'))
      neg.add_allowed_type('HMAC-SHA1')
      assert(neg.allowed?('HMAC-SHA1', 'DH-SHA1'))
      assert(neg.allowed?('HMAC-SHA1', 'no-encryption'))
      assert(!neg.allowed?('HMAC-SHA256', 'DH-SHA256'))
      assert(!neg.allowed?('HMAC-SHA256', 'no-encryption'))
      neg.add_allowed_type('HMAC-SHA256', 'DH-SHA256')
      assert(neg.allowed?('HMAC-SHA1', 'DH-SHA1'))
      assert(neg.allowed?('HMAC-SHA1', 'no-encryption'))
      assert(neg.allowed?('HMAC-SHA256', 'DH-SHA256'))
      assert(!neg.allowed?('HMAC-SHA256', 'no-encryption'))
      assert_equal(neg.get_allowed_type, ['HMAC-SHA1', 'DH-SHA1'])
    end

    def test_bad_assoc_type
      assert_raises(ProtocolError) {
        AssociationNegotiator.new([['OMG', 'Ponies']])
      }
    end

    def test_bad_session_type
      assert_raises(ProtocolError) {
        AssociationNegotiator.new([['HMAC-SHA1', 'OMG-Ponies']])
      }
    end

    def test_default_negotiator
      assert_equal(DefaultNegotiator.get_allowed_type,
                   ['HMAC-SHA1', 'DH-SHA1'])
      assert(DefaultNegotiator.allowed?('HMAC-SHA256', 'no-encryption'))
    end

    def test_encrypted_negotiator
      assert_equal(EncryptedNegotiator.get_allowed_type,
                   ['HMAC-SHA1', 'DH-SHA1'])
      assert(!EncryptedNegotiator.allowed?('HMAC-SHA256', 'no-encryption'))
    end
  end
end
