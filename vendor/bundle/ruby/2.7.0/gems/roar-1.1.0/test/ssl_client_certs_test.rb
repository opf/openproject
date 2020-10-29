require 'test_helper'

require "roar"
require 'roar/transport/net_http/request'
require 'roar/transport/net_http'


class SslClientCertsTest < MiniTest::Spec

  describe Roar::Transport::NetHTTP do

    describe "instance methods" do

      let(:url) { "http://www.bbc.co.uk" }
      let(:as) { "application/xml" }

      let(:transport) { Roar::Transport::NetHTTP.new }

      describe "options passed to the request object (private #call method)" do

        let(:options) { { uri: url, as: as, pem_file: "test/fixtures/sample.pem", ssl_verify_mode: "ssl_verify_mode" } }

        describe "option handling" do

          it "provides all options to the Request object" do

            request_mock = MiniTest::Mock.new
            request_mock.expect :call, nil, [Net::HTTP::Get]

            options_assertions = lambda { |argument_options|
              assert_equal argument_options, options
              request_mock
            }

            Roar::Transport::NetHTTP::Request.stub :new, options_assertions do
              transport.get_uri(options)
            end
          end
        end
      end
    end
  end

  describe Roar::Transport::NetHTTP::Request do

    describe "instance methods" do
      describe "#initialize" do

        describe "client certificate configuration" do

          let(:uri) { URI.parse("http://www.bbc.co.uk") }
          let(:options) { { uri: uri, pem_file: pem_file, ssl_verify_mode: ssl_verify_mode } }

          let(:request) { Roar::Transport::NetHTTP::Request.new(options) }
          let(:net_http_instance) { request.instance_variable_get(:@http) }
          let(:ssl_verify_mode) { nil }

          describe "when a pem file has been provided with the request options" do

            let(:pem_file) { File.expand_path("test/fixtures/sample.pem", File.expand_path('../..', __FILE__)) }

            let(:pem) { File.read(pem_file) }
            let(:cert) { OpenSSL::X509::Certificate.new(pem) }
            let(:key) { OpenSSL::PKey::RSA.new(pem) }

            it "sets the client to use an ssl connection" do
              assert(net_http_instance.use_ssl?, "Net::HTTP connection uses ssl")
            end

            it "sets the client cert" do
              assert_equal(net_http_instance.cert.to_s, cert.to_s)
            end
            it "sets the client key" do
              assert_equal(net_http_instance.key.to_s, key.to_s)
            end
            it "defaults the verify mode to OpenSSL::SSL::VERIFY_PEER when no option provided" do
              assert_equal(net_http_instance.verify_mode, OpenSSL::SSL::VERIFY_PEER)
            end

            describe "verify mode is specified" do

              let(:ssl_verify_mode) { OpenSSL::SSL::VERIFY_NONE }

              it "sets the client verify mode to that option provided" do
                assert_equal(net_http_instance.verify_mode, ssl_verify_mode)
              end
            end
          end

          describe "when a pem file has not been provided in the request options" do

            let(:pem_file) { nil }

            it "does not set the client to use an ssl connection" do
              refute(net_http_instance.use_ssl?, "Net::HTTP connection do not use SSL")
            end
          end
        end
      end
    end
  end
end
