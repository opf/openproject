require 'test_helper'
require 'integration/runner'
require 'roar/http_verbs'
require 'roar/json'

class HttpVerbsTest < MiniTest::Spec
  BandRepresenter = Integration::BandRepresenter

  # keep this class clear of Roar modules.
  class Band
    attr_accessor :name, :label

    def label=(v) # in ruby 2.2, #label= is not there, all at sudden. what *is* that?
      @label = v
    end
  end

  let (:band) { OpenStruct.new(:name => "bodyjar").extend(Roar::HttpVerbs, BandRepresenter) }


  describe "HttpVerbs" do
    before do
      @band = Band.new
      @band.extend(BandRepresenter)
      @band.extend(Roar::HttpVerbs)
    end

    describe "transport_engine" do
      before do
        @http_verbs = Roar::HttpVerbs
        @net_http   = Roar::Transport::NetHTTP
      end

      it "has a default set in the transport module level" do
        assert_equal @net_http, @band.transport_engine
      end

      it "allows changing on instance level" do
        @band.transport_engine = :soap
        assert_equal @net_http, @http_verbs.transport_engine
        assert_equal :soap, @band.transport_engine
      end
    end

    describe "HttpVerbs.get" do
      it "returns instance from incoming representation" do
        band = @band.get(uri: "http://localhost:4567/bands/slayer", as: "application/json")
        assert_equal "Slayer", band.name
        assert_equal "Canadian Maple", band.label
      end

      # FIXME: move to faraday test.
      require 'roar/transport/faraday'
      describe 'a non-existent resource' do
        it 'handles HTTP errors and raises a ResourceNotFound error with FaradayHttpTransport' do
          @band.transport_engine = Roar::Transport::Faraday
          assert_raises(::Faraday::Error::ResourceNotFound) do
            @band.get(uri: 'http://localhost:4567/bands/anthrax', as: "application/json")
          end
        end

        it 'returns Roar::Transport::Error for NetHttpTransport in case of non 20x' do
          @band.transport_engine = Roar::Transport::NetHTTP

          exception = assert_raises(Roar::Transport::Error) do
            @band.get(uri: 'http://localhost:4567/bands/anthrax', as: "application/json")
          end

          exception.response.code.must_equal "404"
        end
      end
    end

    describe "#get" do
      it "updates instance with incoming representation" do
        @band.get(:uri => "http://localhost:4567/bands/slayer", :as => "application/json")
        assert_equal ["Slayer", "Canadian Maple"], [@band.name, @band.label]
      end
    end

    describe "#post" do
      it "updates instance with incoming representation" do
        @band.name = "Strung Out"
        assert_nil @band.label

        @band.post(:uri => "http://localhost:4567/bands", :as => "application/xml")
        assert_equal "STRUNG OUT", @band.name
        assert_nil @band.label
      end
    end

    describe "#put" do
      it "updates instance with incoming representation" do
        @band.name   = "Strung Out"
        @band.label  = "Fat Wreck"
        @band.put(:uri => "http://localhost:4567/bands/strungout", :as => "application/xml")
        assert_equal "STRUNG OUT", @band.name
        assert_equal "FAT WRECK", @band.label
      end
    end

    describe "#patch" do
      it 'does something' do
        @band.label  = 'Fat Mike'
        @band.patch(:uri => "http://localhost:4567/bands/strungout", :as => "application/xml")
        assert_equal 'FAT MIKE', @band.label
      end
    end

    describe "#delete" do
      it 'does something' do
        @band.delete(:uri => "http://localhost:4567/bands/metallica", :as => "application/xml")
      end
    end


    describe "HTTPS and Authentication" do
      let (:song) { OpenStruct.new(:name => "bodyjar").extend(Roar::HttpVerbs, BandRepresenter) }

      describe "Basic Auth: passing manually" do

      end

      describe "HTTPS: passing manually" do
        verbs do |verb|
          it "allows #{verb}" do
            song.send(verb, :uri => "https://localhost:8443/bands/bodyjar", :as => "application/json")

            if verb == "delete"
              song.name.must_equal "bodyjar"
            else
              song.name.must_equal "Bodyjar"
            end
          end
        end
      end

      describe "HTTPS+Basic Auth: passing manually" do
        it "allows GET" do
          song.get(:uri => "https://localhost:8443/protected", :as => "application/json", :basic_auth => [:admin, :password])

          song.name.must_equal "Bodyjar"
        end
      end
    end

    describe "request customization" do
      it "yields the request object" do
        band.get(:uri => "http://localhost:4567/cookies", :as => "application/json") do |req|
          req.add_field("Cookie", "Yumyum")
        end.name.must_equal "Bodyjar"
      end
    end
  end
end
