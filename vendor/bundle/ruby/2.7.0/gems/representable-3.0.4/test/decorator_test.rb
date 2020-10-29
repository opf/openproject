require 'test_helper'

class DecoratorTest < MiniTest::Spec
  class SongRepresentation < Representable::Decorator
    include Representable::JSON
    property :name
  end

  class AlbumRepresentation < Representable::Decorator
    include Representable::JSON

    collection :songs, :class => Song, :extend => SongRepresentation
  end

  class RatingRepresentation < Representable::Decorator
    include Representable::JSON

    property :system
    property :value
  end

  let(:song) { Song.new("Mama, I'm Coming Home") }
  let(:album) { Album.new([song]) }

  let(:rating) { OpenStruct.new(system: 'MPAA', value: 'R') }

  describe "inheritance" do
    let(:inherited_decorator) do
      Class.new(AlbumRepresentation) do
        property :best_song
      end.new(Album.new([song], "Stand Up"))
    end

    it { inherited_decorator.to_hash.must_equal({"songs"=>[{"name"=>"Mama, I'm Coming Home"}], "best_song"=>"Stand Up"}) }
  end

  let(:decorator) { AlbumRepresentation.new(album) }

  let(:rating_decorator) { RatingRepresentation.new(rating) }

  it "renders" do
    decorator.to_hash.must_equal({"songs"=>[{"name"=>"Mama, I'm Coming Home"}]})
    album.wont_respond_to :to_hash
    song.wont_respond_to :to_hash # DISCUSS: weak test, how to assert blank slate?
    # no @representable_attrs in decorated objects
    song.wont_be(:instance_variable_defined?, :@representable_attrs)

    rating_decorator.to_hash.must_equal({"system" => "MPAA", "value" => "R"})
  end

  describe "#from_hash" do
    it "returns represented" do
      decorator.from_hash({"songs"=>[{"name"=>"Mama, I'm Coming Home"}]}).must_equal album
    end

    it "parses" do
      decorator.from_hash({"songs"=>[{"name"=>"Atomic Garden"}]})
      album.songs.first.must_be_kind_of Song
      album.songs.must_equal [Song.new("Atomic Garden")]
      album.wont_respond_to :to_hash
      song.wont_respond_to :to_hash # DISCUSS: weak test, how to assert blank slate?
    end
  end

  describe "#decorated" do
    it "is aliased to #represented" do
      AlbumRepresentation.prepare(album).decorated.must_equal album
    end
  end


  describe "inline decorators" do
    representer!(decorator: true) do
      collection :songs, :class => Song do
        property :name
      end
    end

    it "does not pollute represented" do
      representer.new(album).from_hash({"songs"=>[{"name"=>"Atomic Garden"}]})

      # no @representable_attrs in decorated objects
      song.wont_be(:instance_variable_defined?, :@representable_attrs)
      album.wont_be(:instance_variable_defined?, :@representable_attrs)
    end
  end
end

require "uber/inheritable_attr"
class InheritanceWithDecoratorTest < MiniTest::Spec
  class Twin
    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Representable::Decorator){ include Representable::Hash }
  end

  class Album < Twin
    representer_class.property :title # Twin.representer_class.clone
  end

  class Song < Twin # Twin.representer_class.clone
  end

  it do
    Twin.representer_class.definitions.size.must_equal 0
    Album.representer_class.definitions.size.must_equal 1
    Song.representer_class.definitions.size.must_equal 0
  end
end