require "test_helper"
require "disposable/twin/parent.rb"

class TwinParentTest < MiniTest::Spec
  module Model
    Album = Struct.new(:id, :artist, :songs)
    Artist = Struct.new(:name)
    Song  = Struct.new(:title, :composer)
  end

  class Album < Disposable::Twin
    feature Parent

    property :id

    property :artist do
      property :name
    end

    collection :songs do
      property :title
      property :composer do
        property :name
      end
    end
  end

  let (:album) { Album.new(Model::Album.new(1, Model::Artist.new("Helloween"), [Model::Song.new("I'm Alive", Model::Artist.new("Kai Hansen"))])) }

  it { expect(album.parent).must_be_nil }
  it { expect(album.artist.parent).must_equal album }
  it { expect(album.songs[0].parent).must_equal album }
  it { expect(album.songs[0].composer.parent).must_equal album.songs[0] }

  describe "Collection#append" do
    it do
      album.songs.append(Model::Song.new)
      expect(album.songs[1].parent).must_equal album
    end
  end
end
