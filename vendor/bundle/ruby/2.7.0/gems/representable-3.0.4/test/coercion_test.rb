require 'test_helper'
require 'representable/coercion'

class VirtusCoercionTest < MiniTest::Spec
  representer! do
    include Representable::Coercion

    property :title # no coercion.
    property :length, :type => Float

    property :band, :class => OpenStruct do
      property :founded, :type => Integer
    end

    collection :songs, :class => OpenStruct do
      property :ok, :type => Virtus::Attribute::Boolean
    end
  end

  let(:album) { OpenStruct.new(:title => "Dire Straits", :length => 41.34,
    :band  => OpenStruct.new(:founded => "1977"),
    :songs => [OpenStruct.new(:ok => 1), OpenStruct.new(:ok => 0)]) }

  it { album.extend(representer).to_hash.must_equal({"title"=>"Dire Straits", "length"=>41.34, "band"=>{"founded"=>1977}, "songs"=>[{"ok"=>true}, {"ok"=>false}]}) }

  it {
    album = OpenStruct.new
    album.extend(representer)
    album.from_hash({"title"=>"Dire Straits", "length"=>"41.34", "band"=>{"founded"=>"1977"}, "songs"=>[{"ok"=>1}, {"ok"=>0}]})

    # it
    album.length.must_equal 41.34
    album.band.founded.must_equal 1977
    album.songs[0].ok.must_equal true
  }


  describe "with user :parse_filter and :render_filter" do
    representer! do
      include Representable::Coercion

      property :length, :type => Float,
      :parse_filter  => lambda { |input, options| "#{input}.1" }, # happens BEFORE coercer.
      :render_filter => lambda { |fragment,*| "#{fragment}.1" }
    end

    # user's :parse_filter(s) are run before coercion.
    it { OpenStruct.new.extend(representer).from_hash("length"=>"1").length.must_equal 1.1 }
    # user's :render_filter(s) are run before coercion.
    it { OpenStruct.new(:length=>1).extend(representer).to_hash.must_equal({"length" => 1.1}) }
  end
end