require "test_helper"

class TwinSyncTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name)
  end


  module Twin
    class Album < Disposable::Twin
      feature Setup
      feature Sync

      property :name

      collection :songs do
        property :title

        property :composer do
          property :name
        end
      end

      property :artist do
        property :name
      end
    end
  end


  let (:song) { Model::Song.new() }
  let (:composer) { Model::Artist.new(nil) }
  let (:song_with_composer) { Model::Song.new(nil, composer) }
  let (:artist) { Model::Artist.new(nil) }


  describe "#sync" do
    let (:album) { Model::Album.new(nil, [song, song_with_composer], artist) }

    # with populated model.
    it do
      twin = Twin::Album.new(album)

      # this usually happens in Contract::Validate or in from_* in a representer
      fill_out!(twin)

      # not written to model, yet.
      expect(album.name).must_be_nil
      expect(album.songs[0].title).must_be_nil
      expect(album.songs[1].title).must_be_nil
      expect(album.songs[1].composer.name).must_be_nil
      expect(album.artist.name).must_be_nil

      twin.sync

      expect(album.name).must_equal "Live And Dangerous"
      expect(album.songs[0]).must_be_instance_of Model::Song
      expect(album.songs[1]).must_be_instance_of Model::Song
      expect(album.songs[0].title).must_equal "Southbound"
      expect(album.songs[1].title).must_equal "The Boys Are Back In Town"
      expect(album.songs[1].composer).must_be_instance_of Model::Artist
      expect(album.songs[1].composer.name).must_equal "Lynott"
      expect(album.artist).must_be_instance_of Model::Artist
      expect(album.artist.name).must_equal "Thin Lizzy"
    end

    # with empty, not populated model.
    it do
      album = Model::Album.new(nil, [])
      twin  = Twin::Album.new(album)

      # this usually happens in Contract::Validate or in from_* in a representer
      twin.name = "Live And Dangerous"

      twin.songs.insert(0, song)
      twin.songs.insert(1, song_with_composer)

      twin.songs[0].title = "Southbound"
      twin.songs[1].title = "The Boys Are Back In Town"
      twin.songs[1].composer.name = "Lynott"

      # not written to model, yet.
      expect(album.name).must_be_nil
      expect(album.songs).must_equal []
      expect(album.artist).must_be_nil

      twin.sync # this assigns a new collection via #songs=.

      expect(album.name).must_equal "Live And Dangerous"
      expect(album.songs[0].title).must_equal "Southbound"
      expect(album.songs[1].title).must_equal "The Boys Are Back In Town"
      expect(album.songs[1].composer.name).must_equal "Lynott"
    end

    # save with block.
    describe "#to_nested_hash" do
      let (:twin) { Twin::Album.new(album) }

      it "creates nested_hash and doesn't sync" do
        # this usually happens in Contract::Validate or in from_* in a representer
        fill_out!(twin)

        nested_hash = nil
        twin.sync do |hash|
          nested_hash = hash
        end

        expect(nested_hash).must_equal({"name"=>"Live And Dangerous", "songs"=>[{"title"=>"Southbound", "composer"=>nil}, {"title"=>"The Boys Are Back In Town", "composer"=>{"name"=>"Lynott"}}], "artist"=>{"name"=>"Thin Lizzy"}})

        # nothing written to model.
        expect(album.name).must_be_nil
        expect(album.songs[0].title).must_be_nil
        expect(album.songs[1].title).must_be_nil
        expect(album.songs[1].composer.name).must_be_nil
        expect(album.artist.name).must_be_nil
      end

      describe "nil values" do
        it "includes nil values, including nil collections" do
          twin = Twin::Album.new(Model::Album.new(nil,
            nil, # uninitialized nil collection.
            nil)
          )

          nested_hash = nil
          twin.sync { |hash| nested_hash = hash }

          expect(nested_hash).must_equal({"name"=>nil, "artist"=>nil})
        end

        it "includes empty collections" do
          twin = Twin::Album.new(Model::Album.new(nil,
            [], # empty collection.
            nil)
          )

          nested_hash = nil
          twin.sync { |hash| nested_hash = hash }

          expect(nested_hash).must_equal({"name"=>nil, "songs"=>[], "artist"=>nil})
        end
      end
    end


    def fill_out!(twin)
      twin.name = "Live And Dangerous"
      twin.songs[0].title = "Southbound"
      twin.songs[1].title = "The Boys Are Back In Town"
      twin.songs[1].composer.name = "Lynott"
      twin.artist.name = "Thin Lizzy"
    end
  end
end
