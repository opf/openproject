require 'openid/extensions/ax'
require 'openid/message'
require 'openid/consumer/responses'
require 'openid/consumer/discovery'
require 'openid/consumer/checkid_request'

module OpenID
  module AX
    class BogusAXMessage < AXMessage
      @mode = 'bogus'

      def get_extension_args
        new_args
      end

      def do_check_mode(args)
        check_mode(args)
      end

      def do_check_mode_new_args
        check_mode(new_args)
      end
    end

    class AXMessageTest < Test::Unit::TestCase
      def setup
        @bax = BogusAXMessage.new
      end

      def test_check_mode
        assert_raises(Error) { @bax.do_check_mode({'mode' => 'fetch_request'})}
        @bax.do_check_mode({'mode' => @bax.mode})
      end

      def test_check_mode_new_args
        @bax.do_check_mode_new_args
      end
    end

    class AttrInfoTest < Test::Unit::TestCase
      def test_construct
        assert_raises(ArgumentError) { AttrInfo.new }
        type_uri = 'uri geller'
        ainfo = AttrInfo.new(type_uri)

        assert_equal(type_uri, ainfo.type_uri)
        assert_equal(1, ainfo.count)
        assert_equal(false, ainfo.required)
        assert_equal(nil, ainfo.ns_alias)
      end
    end

    class ToTypeURIsTest < Test::Unit::TestCase
      def setup
        @aliases = NamespaceMap.new
      end

      def test_empty
        [nil, ''].each{|empty|
          uris = AX.to_type_uris(@aliases, empty)
          assert_equal([], uris)
        }
      end

      def test_undefined
        assert_raises(IndexError) {
          AX.to_type_uris(@aliases, 'http://janrain.com/')
        }
      end

      def test_one
        uri = 'http://janrain.com/'
        name = 'openid_hackers'
        @aliases.add_alias(uri, name)
        uris = AX::to_type_uris(@aliases, name)
        assert_equal([uri], uris)
      end

      def test_two
        uri1 = 'http://janrain.com/'
        name1 = 'openid_hackers'
        @aliases.add_alias(uri1, name1)

        uri2 = 'http://jyte.com/'
        name2 = 'openid_hack'
        @aliases.add_alias(uri2, name2)

        uris = AX.to_type_uris(@aliases, [name1, name2].join(','))
        assert_equal([uri1, uri2], uris)
      end
    end

    class ParseAXValuesTest < Test::Unit::TestCase
      def ax_values(ax_args, expected_args)
        msg = KeyValueMessage.new
        msg.parse_extension_args(ax_args)
        assert_equal(expected_args, msg.data)
      end

      def ax_error(ax_args, error)
        msg = KeyValueMessage.new
        assert_raises(error) {
          msg.parse_extension_args(ax_args)
        }
      end

      def test_empty_is_valid
        ax_values({}, {})
      end

      def test_missing_value_for_alias_explodes
        ax_error({'type.foo'=>'urn:foo'}, IndexError)
      end

      def test_count_present_but_not_value
        ax_error({'type.foo'=>'urn:foo', 'count.foo' => '1'}, IndexError)
      end

      def test_invalid_count_value
        msg = FetchRequest.new
        assert_raises(Error) {
          msg.parse_extension_args({'type.foo'=>'urn:foo', 
                                     'count.foo' => 'bogus'})
        }
      end

      def test_request_unlimited_values
        msg = FetchRequest.new
        args = {'mode' => 'fetch_request',
          'required' => 'foo',
          'type.foo' => 'urn:foo',
          'count.foo' => UNLIMITED_VALUES
        }
        msg.parse_extension_args(args)
        foo = msg.attributes[0]
        assert_equal(UNLIMITED_VALUES, foo.count)
        assert(foo.wants_unlimited_values?)
      end

      def test_long_alias
        # spec says we must support at least 32 character-long aliases
        name = 'x' * MINIMUM_SUPPORTED_ALIAS_LENGTH

        msg = KeyValueMessage.new
        args = {
          "type.#{name}" => 'urn:foo',
          "count.#{name}" => '1',
          "value.#{name}.1" => 'first',
        }
        msg.parse_extension_args(args)
        assert_equal(['first'],msg['urn:foo'])
      end

      def test_invalid_alias
        types = [
                 KeyValueMessage,
                 FetchRequest
                ]
        inputs = [
                  {'type.a.b'=>'urn:foo',
                    'count.a.b'=>'1'},
                  {'type.a,b'=>'urn:foo',
                    'count.a,b'=>'1'},
                 ]
        types.each{|t|
          inputs.each{|input|
            msg = t.new
            assert_raises(Error) {msg.parse_extension_args(input)}
          }
        }
      end

      def test_count_present_and_is_zero
        ax_values(
                  {'type.foo'=>'urn:foo',
                    'count.foo'=>'0',
                  },
                  {'urn:foo'=>[]}
                  )
      end

      def test_singleton_empty
        ax_values(
                  {'type.foo'=>'urn:foo',
                    'value.foo'=>'',
                  },
                  {'urn:foo'=>[]}
                  )
      end

      def test_double_alias
        ax_error(
                 {'type.foo'=>'urn:foo',
                   'value.foo'=>'',
                   'type.bar'=>'urn:foo',
                   'value.bar'=>'',
                 },
                 IndexError
                 )
      end

      def test_double_singleton
        ax_values(
                  {'type.foo'=>'urn:foo',
                    'value.foo'=>'',
                    'type.bar'=>'urn:bar',
                    'value.bar'=>'',
                  },
                  {'urn:foo'=>[],'urn:bar'=>[]}
                  )
      end

      def singleton_value
        ax_values(
                  {'type.foo'=>'urn:foo',
                    'value.foo'=>'something',
                  },
                  {'urn:foo'=>['something']}
                  )     
      end
    end

    class FetchRequestTest < Test::Unit::TestCase
      def setup
        @msg = FetchRequest.new
        @type_a = 'http://janrain.example.com/a'
        @name_a = 'a'
      end

      def test_mode
        assert_equal('fetch_request', @msg.mode)
      end

      def test_construct
        assert_equal({}, @msg.requested_attributes)
        assert_equal(nil, @msg.update_url)

        msg = FetchRequest.new('hailstorm')
        assert_equal({}, msg.requested_attributes)
        assert_equal('hailstorm', msg.update_url)
      end

      def test_add
        uri = 'mud://puddle'

        assert(! @msg.member?(uri))
        a = AttrInfo.new(uri)
        @msg.add(a)
        assert(@msg.member?(uri))
      end

      def test_add_twice
        uri = 'its://raining'
        a = AttrInfo.new(uri)
        @msg.add(a)
        assert_raises(IndexError) {@msg.add(a)}
      end

      def do_extension_args(expected_args)
        expected_args['mode'] = @msg.mode
        assert_equal(expected_args, @msg.get_extension_args)
      end

      def test_get_extension_args_empty
        do_extension_args({})
      end

      def test_get_extension_args_no_alias
        a = AttrInfo.new('foo://bar')
        @msg.add(a)
        ax_args = @msg.get_extension_args
        ax_args.each{|k,v|
          if v == a.type_uri and k.index('type.') == 0
            @name = k[5..-1]
            break
          end
        }
        do_extension_args({'type.'+@name => a.type_uri,
                            'if_available' => @name})
      end

      def test_get_extension_args_alias_if_available
        a = AttrInfo.new('type://of.transportation',
                         'transport')
        @msg.add(a)
        do_extension_args({'type.'+a.ns_alias => a.type_uri,
                            'if_available' => a.ns_alias})
      end

      def test_get_extension_args_alias_req
        a = AttrInfo.new('type://of.transportation',
                         'transport',
                         true)
        @msg.add(a)
        do_extension_args({'type.'+a.ns_alias => a.type_uri,
                            'required' => a.ns_alias})
      end

      def test_get_required_attrs_empty
        assert_equal([], @msg.get_required_attrs)
      end

      def test_parse_extension_args_extra_type
        args = {
          'mode' => 'fetch_request',
          'type.' + @name_a => @type_a
        }
        assert_raises(Error) {@msg.parse_extension_args(args)}
      end

      def test_parse_extension_args
        args = {
          'mode' => 'fetch_request',
          'type.' + @name_a => @type_a,
          'if_available' => @name_a
        }
        @msg.parse_extension_args(args)
        assert(@msg.member?(@type_a) )
        assert_equal([@type_a], @msg.requested_types)
        ai = @msg.requested_attributes[@type_a]
        assert(ai.is_a?(AttrInfo))
        assert(!ai.required)
        assert_equal(@type_a, ai.type_uri)
        assert_equal(@name_a, ai.ns_alias)
        assert_equal([ai], @msg.attributes)
      end

      def test_extension_args_idempotent
        args = {
          'mode' => 'fetch_request',
          'type.' + @name_a => @type_a,
          'if_available' => @name_a
        }
        @msg.parse_extension_args(args)
        assert_equal(args, @msg.get_extension_args)
        assert(!@msg.requested_attributes[@type_a].required)
      end

      def test_extension_args_idempotent_count_required
        args = {
          'mode' => 'fetch_request',
          'type.' + @name_a => @type_a,
          'count.' + @name_a => '2',
          'required' => @name_a
        }
        @msg.parse_extension_args(args)
        assert_equal(args, @msg.get_extension_args)
        assert(@msg.requested_attributes[@type_a].required)
      end

      def test_extension_args_count1
        args = {
          'mode' => 'fetch_request',
          'type.' + @name_a => @type_a,
          'count.' + @name_a => '1',
          'if_available' => @name_a
        }
        norm_args = {
          'mode' => 'fetch_request',
          'type.' + @name_a => @type_a,
          'if_available' => @name_a
        }
        @msg.parse_extension_args(args)
        assert_equal(norm_args, @msg.get_extension_args)
      end

      def test_from_openid_request_no_ax
        message = Message.new
        openid_req = Server::OpenIDRequest.new
        openid_req.message = message
        ax_req = FetchRequest.from_openid_request(openid_req)
        assert(ax_req.nil?)
      end

      def test_openid_update_url_verification_error
        openid_req_msg = Message.from_openid_args({
                                                    'mode' => 'checkid_setup',
                                                    'ns' => OPENID2_NS,
                                                    'realm' => 'http://example.com/realm',
                                                    'ns.ax' => AXMessage::NS_URI,
                                                    'ax.update_url' => 'http://different.site/path',
                                                    'ax.mode' => 'fetch_request',
                                                  })
        openid_req = Server::OpenIDRequest.new
        openid_req.message = openid_req_msg
        assert_raises(Error) { 
          FetchRequest.from_openid_request(openid_req)
        }
      end

      def test_openid_no_realm
        openid_req_msg = Message.from_openid_args({
                                                    'mode' => 'checkid_setup',
                                                    'ns' => OPENID2_NS,
                                                    'ns.ax' => AXMessage::NS_URI,
                                                    'ax.update_url' => 'http://different.site/path',
                                                    'ax.mode' => 'fetch_request',
                                                  })
        openid_req = Server::OpenIDRequest.new
        openid_req.message = openid_req_msg
        assert_raises(Error) { 
          FetchRequest.from_openid_request(openid_req)
        }
      end

      def test_openid_update_url_verification_success
        openid_req_msg = Message.from_openid_args({
                                                    'mode' => 'checkid_setup',
                                                    'ns' => OPENID2_NS,
                                                    'realm' => 'http://example.com/realm',
                                                    'ns.ax' => AXMessage::NS_URI,
                                                    'ax.update_url' => 'http://example.com/realm/update_path',
                                                    'ax.mode' => 'fetch_request',
                                                  })
        openid_req = Server::OpenIDRequest.new
        openid_req.message = openid_req_msg
        fr = FetchRequest.from_openid_request(openid_req)
        assert(fr.is_a?(FetchRequest))
      end

      def test_openid_update_url_verification_success_return_to
        openid_req_msg = Message.from_openid_args({
                                                    'mode' => 'checkid_setup',
                                                    'ns' => OPENID2_NS,
                                                    'return_to' => 'http://example.com/realm',
                                                    'ns.ax' => AXMessage::NS_URI,
                                                    'ax.update_url' => 'http://example.com/realm/update_path',
                                                    'ax.mode' => 'fetch_request',
                                                  })
        openid_req = Server::OpenIDRequest.new
        openid_req.message = openid_req_msg
        fr = FetchRequest.from_openid_request(openid_req)
        assert(fr.is_a?(FetchRequest))
      end

      def test_add_extension
        openid_req_msg = Message.from_openid_args({
                                                    'mode' => 'checkid_setup',
                                                    'ns' => OPENID2_NS,
                                                    'return_to' => 'http://example.com/realm',
                                                  })

        e = OpenID::OpenIDServiceEndpoint.new
        openid_req = Consumer::CheckIDRequest.new(nil, e)
        openid_req.message = openid_req_msg

        fr = FetchRequest.new
        fr.add(AttrInfo.new("urn:bogus"))

        openid_req.add_extension(fr)

        expected = {
          'mode' => 'fetch_request',
          'if_available' => 'ext0',
          'type.ext0' => 'urn:bogus',
        }

        expected.each { |k,v|
          assert(openid_req.message.get_arg(AXMessage::NS_URI, k) == v)
        }
      end
    end

    class FetchResponseTest < Test::Unit::TestCase
      def setup
        @msg = FetchResponse.new
        @value_a = 'commodity'
        @type_a = 'http://blood.transfusion/'
        @name_a = 'george'
        @request_update_url = 'http://some.url.that.is.awesome/'
      end

      def test_construct
        assert_equal(nil, @msg.update_url)
        assert_equal({}, @msg.data)
      end

      def test_get_extension_args_empty
        eargs = {
          'mode' => 'fetch_response'
        }
        assert_equal(eargs, @msg.get_extension_args)
      end

      def test_get_extension_args_empty_request
        eargs = {
          'mode' => 'fetch_response'
        }
        req = FetchRequest.new
        assert_equal(eargs, @msg.get_extension_args(req))
      end

      def test_get_extension_args_empty_request_some
        uri = 'http://not.found/'
        name = 'ext0'
        eargs = {
          'mode' => 'fetch_response',
          'type.' + name => uri,
          'count.' + name => '0'
        }
        req = FetchRequest.new
        req.add(AttrInfo.new(uri))
        assert_equal(eargs, @msg.get_extension_args(req))
      end

      def test_update_url_in_response
        uri = 'http://not.found/'
        name = 'ext0'
        eargs = {
          'mode' => 'fetch_response',
          'update_url' => @request_update_url,
          'type.' + name => uri,
          'count.' + name => '0'
        }
        req = FetchRequest.new(@request_update_url)
        req.add(AttrInfo.new(uri))
        assert_equal(eargs, @msg.get_extension_args(req))
      end

      def test_get_extension_args_some_request
        eargs = {
          'mode' => 'fetch_response',
          'type.' + @name_a => @type_a,
          'value.' + @name_a + '.1' => @value_a,
          'count.' + @name_a =>  '1'
        }
        req = FetchRequest.new
        req.add(AttrInfo.new(@type_a, @name_a))
        @msg.add_value(@type_a, @value_a)
        assert_equal(eargs, @msg.get_extension_args(req))
      end

      def test_get_extension_args_some_not_request
        req = FetchRequest.new
        @msg.add_value(@type_a, @value_a)
        assert_raises(IndexError) {@msg.get_extension_args(req)}
      end

      def test_get_single_success
        req = FetchRequest.new
        @msg.add_value(@type_a, @value_a)
        assert_equal(@value_a, @msg.get_single(@type_a))
      end

      def test_get_single_none
        assert_equal(nil, @msg.get_single(@type_a))
      end

      def test_get_single_extra
        @msg.set_values(@type_a, ['x', 'y'])
        assert_raises(Error) { @msg.get_single(@type_a) }
      end

      def test_from_success_response
        uri = 'http://under.the.sea/'
        name = 'ext0'
        value = 'snarfblat'

        m = OpenID::Message.from_openid_args({
                                               'mode' => 'id_res',
                                               'ns' => OPENID2_NS,
                                               'ns.ax' => AXMessage::NS_URI,
                                               'ax.update_url' => 'http://example.com/realm/update_path',
                                               'ax.mode' => 'fetch_response',
                                               'ax.type.' + name => uri,
                                               'ax.count.' + name => '1',
                                               'ax.value.' + name + '.1' => value,
                                             })

        e = OpenID::OpenIDServiceEndpoint.new()
        resp = OpenID::Consumer::SuccessResponse.new(e, m, [])

        ax_resp = FetchResponse.from_success_response(resp, false)

        values = ax_resp[uri]
        assert_equal(values, [value])
      end

      def test_from_success_response_empty
        e = OpenID::OpenIDServiceEndpoint.new()
        m = OpenID::Message.from_openid_args({'mode' => 'id_res'})
        resp = OpenID::Consumer::SuccessResponse.new(e, m, [])
        ax_resp = FetchResponse.from_success_response(resp)
        assert(ax_resp.nil?)
      end
    end

    class StoreRequestTest < Test::Unit::TestCase
      def setup
        @msg = StoreRequest.new
        @type_a = 'http://oranges.are.for/'
        @name_a = 'juggling'
      end

      def test_construct
        assert_equal({}, @msg.data)
      end

      def test_get_extension_args_empty
        eargs = {
          'mode' => 'store_request'
        }
        assert_equal(eargs, @msg.get_extension_args)
      end

      def test_get_extension_args_nonempty
        @msg.set_values(@type_a, ['foo','bar'])
        aliases = NamespaceMap.new
        aliases.add_alias(@type_a, @name_a)
        eargs = {
          'mode' => 'store_request',
          'type.' + @name_a => @type_a,
          'value.' + @name_a + '.1' => 'foo',
          'value.' + @name_a + '.2' => 'bar',
          'count.' + @name_a =>  '2'
        }
        assert_equal(eargs, @msg.get_extension_args(aliases))
      end
    end

    class StoreResponseTest < Test::Unit::TestCase
      def test_success
        msg = StoreResponse.new
        assert(msg.succeeded?)
        assert(!msg.error_message)
        assert_equal({'mode' => 'store_response_success'}, 
                     msg.get_extension_args)
      end

      def test_fail_nomsg
        msg = StoreResponse.new(false)
        assert(! msg.succeeded? )
        assert(! msg.error_message )
        assert_equal({'mode' => 'store_response_failure'}, 
                     msg.get_extension_args)
      end

      def test_fail_msg
        reason = "because I said so"
        msg = StoreResponse.new(false, reason)
        assert(! msg.succeeded? )
        assert_equal(reason,  msg.error_message)
        assert_equal({'mode' => 'store_response_failure', 'error' => reason}, 
                     msg.get_extension_args)
      end
    end
  end
end
