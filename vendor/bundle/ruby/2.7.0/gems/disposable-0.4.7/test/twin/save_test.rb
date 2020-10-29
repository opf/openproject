require 'test_helper'

class SaveTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :composer)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name)
  end


  module Twin
    class Album < Disposable::Twin
      feature Setup
      feature Sync
      feature Save

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


  let (:song) { Model::Song.new().extend(Disposable::Saveable) }
  let (:composer) { Model::Artist.new(nil).extend(Disposable::Saveable) }
  let (:song_with_composer) { Model::Song.new(nil, composer).extend(Disposable::Saveable) }
  let (:artist) { Model::Artist.new(nil).extend(Disposable::Saveable) }


  let (:album) { Model::Album.new(nil, [song, song_with_composer], artist).extend(Disposable::Saveable) }

  let (:twin) { Twin::Album.new(album) }

  # with populated model.
  it do
    fill_out!(twin)

    twin.save

    # sync happened.
    expect(album.name).must_equal "Live And Dangerous"
    expect(album.songs[0]).must_be_instance_of Model::Song
    expect(album.songs[1]).must_be_instance_of Model::Song
    expect(album.songs[0].title).must_equal "Southbound"
    expect(album.songs[1].title).must_equal "The Boys Are Back In Town"
    expect(album.songs[1].composer).must_be_instance_of Model::Artist
    expect(album.songs[1].composer.name).must_equal "Lynott"
    expect(album.artist).must_be_instance_of Model::Artist
    expect(album.artist.name).must_equal "Thin Lizzy"

    # saved?
    expect(album.saved?).must_equal true
    expect(album.songs[0].saved?).must_equal true
    expect(album.songs[1].saved?).must_equal true
    expect(album.songs[1].composer.saved?).must_equal true
    expect(album.artist.saved?).must_equal true
  end

  #save returns result.
  it { expect(twin.save).must_equal true }
  it do
    album.instance_eval { def save; false; end }
    expect(twin.save).must_equal false
  end

  # with save{}.
  it do
    twin = Twin::Album.new(album)

    # this usually happens in Contract::Validate or in from_* in a representer
    fill_out!(twin)

    nested_hash = nil
    twin.save do |hash|
      nested_hash = hash
    end

    expect(nested_hash).must_equal({"name"=>"Live And Dangerous", "songs"=>[{"title"=>"Southbound", "composer"=>nil}, {"title"=>"The Boys Are Back In Town", "composer"=>{"name"=>"Lynott"}}], "artist"=>{"name"=>"Thin Lizzy"}})

    # nothing written to model.
    expect(album.name).must_be_nil
    expect(album.songs[0].title).must_be_nil
    expect(album.songs[1].title).must_be_nil
    expect(album.songs[1].composer.name).must_be_nil
    expect(album.artist.name).must_be_nil

    # nothing saved.
    # saved?
    expect(album.saved?).must_be_nil
    expect(album.songs[0].saved?).must_be_nil
    expect(album.songs[1].saved?).must_be_nil
    expect(album.songs[1].composer.saved?).must_be_nil
    expect(album.artist.saved?).must_be_nil
  end


  # save: false
  module Twin
    class AlbumWithSaveFalse < Disposable::Twin
      feature Setup
      feature Sync
      feature Save

      property :name

      collection :songs, save: false do
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

  # with save: false.
  it do
    twin = Twin::AlbumWithSaveFalse.new(album)

    fill_out!(twin)

    twin.save

    # sync happened.
    expect(album.name).must_equal "Live And Dangerous"
    expect(album.songs[0]).must_be_instance_of Model::Song
    expect(album.songs[1]).must_be_instance_of Model::Song
    expect(album.songs[0].title).must_equal "Southbound"
    expect(album.songs[1].title).must_equal "The Boys Are Back In Town"
    expect(album.songs[1].composer).must_be_instance_of Model::Artist
    expect(album.songs[1].composer.name).must_equal "Lynott"
    expect(album.artist).must_be_instance_of Model::Artist
    expect(album.artist.name).must_equal "Thin Lizzy"

    # saved?
    expect(album.saved?).must_equal true
    expect(album.songs[0].saved?).must_be_nil
    expect(album.songs[1].saved?).must_be_nil
    expect(album.songs[1].composer.saved?).must_be_nil # doesn't get saved.
    expect(album.artist.saved?).must_equal true
  end

  def fill_out!(twin)
    twin.name = "Live And Dangerous"
    twin.songs[0].title = "Southbound"
    twin.songs[1].title = "The Boys Are Back In Town"
    twin.songs[1].composer.name = "Lynott"
    twin.artist.name = "Thin Lizzy"
  end
end


# TODO: with block

# class SaveWithDynamicOptionsTest < MiniTest::Spec
#   Song = Struct.new(:id, :title, :length) do
#     include Disposable::Saveable
#   end

#   class SongForm < Reform::Form
#     property :title#, save: false
#     property :length, virtual: true
#   end

#   let (:song) { Song.new }
#   let (:form) { SongForm.new(song) }

#   # we have access to original input value and outside parameters.
#   it "xxx" do
#     form.validate("title" => "A Poor Man's Memory", "length" => 10)
#     length_seconds = 120
#     form.save(length: lambda { |value, options| form.model.id = "#{value}: #{length_seconds}" })

#     song.title).must_equal "A Poor Man's Memory"
#     song.length).must_be_nil
#     song.id).must_equal "10: 120"
#   end
# end
