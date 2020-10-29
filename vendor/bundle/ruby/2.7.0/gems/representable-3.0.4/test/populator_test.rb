require "test_helper"

class PopulatorTest < Minitest::Spec
  Song   = Struct.new(:id)
  Artist = Struct.new(:name)
  Album  = Struct.new(:songs, :artist)

  describe "populator: ->{}" do
    representer! do
      collection :songs, populator: ->(input, options) { options[:represented].songs << song = Song.new; song } do
        property :id
      end

      property :artist, populator: ->(input, options) { options[:represented].artist = Artist.new } do
        property :name
      end
    end

    let(:album) { Album.new([]) }

    it do
      album.extend(representer).from_hash("songs"=>[{"id"=>1}, {"id"=>2}], "artist"=>{"name"=>"Waste"})
      album.inspect.must_equal "#<struct PopulatorTest::Album songs=[#<struct PopulatorTest::Song id=1>, #<struct PopulatorTest::Song id=2>], artist=#<struct PopulatorTest::Artist name=\"Waste\">>"
    end
  end

  describe "populator: ->{}, " do

  end
end

class PopulatorFindOrInstantiateTest < Minitest::Spec
  Song = Struct.new(:id, :title, :uid) do
    def self.find_by(attributes={})
      return new(1, "Resist Stan", "abcd") if attributes[:id]==1# we should return the same object here
      new
    end
  end

  Composer = Struct.new(:song)
  Composer.class_eval do
    def song=(v)
      @song = v
      "Absolute nonsense" # this tests that the populator always returns the correct object.
    end

    attr_reader :song
  end

  describe "FindOrInstantiate with property" do
    representer! do
      property :song, populator: Representable::FindOrInstantiate, class: Song do
        property :id
        property :title
      end
    end

    let(:album) { Composer.new.extend(representer).extend(Representable::Debug) }

    it "finds by :id and creates new without :id" do
      album.from_hash({"song"=>{"id" => 1, "title"=>"Resist Stance"}})

      album.song.title.must_equal "Resist Stance" # note how title is updated from "Resist Stan"
      album.song.id.must_equal 1
      album.song.uid.must_equal "abcd" # not changed via populator, indicating this is a formerly "persisted" object.
    end

    it "creates new without :id" do
      album.from_hash({"song"=>{"title"=>"Lower"}})

      album.song.title.must_equal "Lower"
      album.song.id.must_be_nil
      album.song.uid.must_be_nil
    end
  end

  describe "FindOrInstantiate with collection" do
    representer! do
      collection :songs, populator: Representable::FindOrInstantiate, class: Song do
        property :id
        property :title
      end
    end

    let(:album) { Struct.new(:songs).new([]).extend(representer) }

    it "finds by :id and creates new without :id" do
      album.from_hash({"songs"=>[
        {"id" => 1, "title"=>"Resist Stance"},
        {"title"=>"Suffer"}
      ]})

      album.songs[0].title.must_equal "Resist Stance" # note how title is updated from "Resist Stan"
      album.songs[0].id.must_equal 1
      album.songs[0].uid.must_equal "abcd" # not changed via populator, indicating this is a formerly "persisted" object.

      album.songs[1].title.must_equal "Suffer"
      album.songs[1].id.must_be_nil
      album.songs[1].uid.must_be_nil
    end

    # TODO: test with existing collection
  end

end