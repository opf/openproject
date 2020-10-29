require 'test_helper'
require 'roar/client'

class ClientTest < MiniTest::Spec
  representer_for([Roar::Representer]) do
    property :name
    property :band
  end

  let(:song) { Object.new.extend(rpr).extend(Roar::Client) }

  it "adds accessors" do
    song.name = "Social Suicide"
    song.band = "Bad Religion"
    assert_equal "Social Suicide", song.name
    assert_equal "Bad Religion", song.band
  end

  describe "links" do
    representer_for([Roar::JSON, Roar::Hypermedia]) do
      property :name
      link(:self) { never_call_me! }
    end

    it "suppresses rendering" do
      song.name = "Silenced"
      song.to_json.must_equal %{{\"name\":\"Silenced\",\"links\":[]}}
    end

    # since this is considered dangerous, we test the mutuable options.
    it "adds links: false to options" do
      song.to_hash(options = {})
      options.must_equal(user_options: {links: false})
    end
  end
end
