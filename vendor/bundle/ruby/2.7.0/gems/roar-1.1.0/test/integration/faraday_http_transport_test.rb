require 'test_helper'
require 'integration/runner'
require 'roar/transport/faraday'

class FaradayHttpTransportTest < MiniTest::Spec
  describe 'FaradayHttpTransport' do
    let(:url) { "http://localhost:4567/method" }
    let(:body) { "booty" }
    let(:as) { "application/xml" }
    before do
      @transport = Roar::Transport::Faraday.new
    end

    it "#get_uri returns response" do
      @transport.get_uri(uri: url, as: as).must_match_faraday_response :get, url, as
    end

    it "#post_uri returns response" do
      @transport.post_uri(uri: url, body: body, as: as).must_match_faraday_response :post, url, as, body
    end

    it "#put_uri returns response" do
      @transport.put_uri(uri: url, body: body, as: as).must_match_faraday_response :put, url, as, body
    end

    it "#delete_uri returns response" do
      @transport.delete_uri(uri: url, as: as).must_match_faraday_response :delete, url, as
    end

    it "#patch_uri returns response" do
      @transport.patch_uri(uri: url, body: body, as: as).must_match_faraday_response :patch, url, as, body
    end

    describe 'non-existent resource' do
      let(:not_found_url) { 'http://localhost:4567/missing-resource' }

      it '#get_uri raises a ResourceNotFound error' do
        assert_raises(Faraday::Error::ResourceNotFound) do
          @transport.get_uri(uri: not_found_url, as: as).body
        end
      end

      it '#post_uri raises a ResourceNotFound error' do
        assert_raises(Faraday::Error::ResourceNotFound) do
          @transport.post_uri(uri: not_found_url, body: body, as: as).body
        end
      end

      it '#post_uri raises a ResourceNotFound error' do
        assert_raises(Faraday::Error::ResourceNotFound) do
          @transport.post_uri(uri: not_found_url, body: body, as: as).body
        end
      end

      it '#delete_uri raises a ResourceNotFound error' do
        assert_raises(Faraday::Error::ResourceNotFound) do
          @transport.delete_uri(uri: not_found_url, body: body, as: as).body
        end
      end
    end

    describe 'server errors (500 Internal Server Error)' do
      it '#get_uri raises a ClientError' do
        assert_raises(Faraday::Error::ClientError) do
          @transport.get_uri(uri: 'http://localhost:4567/deliberate-error', as: as).body
        end
      end
    end

  end
end

module MiniTest::Assertions

  def assert_faraday_response(type, response, url, as, body = nil)
    headers = response.env[:request_headers]
    assert_equal [as, as], [headers["Accept"], headers["Content-Type"]]
    assert_equal "<method>#{type}#{(' - ' + body) if body}</method>", response.body
  end

end

Faraday::Response.infect_an_assertion :assert_faraday_response, :must_match_faraday_response
