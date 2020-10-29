require 'test_helper'

# reason: unique API for collection (adding, removing, deleting, etc.)
#         delay DB write until saving Twin

# TODO: eg "after delete hook (dynamic_delete)", after_add

class TwinCollectionTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs, :artist)
  end


  module Twin
    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :title
      # property :album, twin: Album
    end

    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      collection :songs, twin: Song
    end
  end

  let (:song) { Model::Song.new(1, "Broken", nil) }
  let (:album) { Model::Album.new(1, "The Rest Is Silence", [song]) }

  describe "reader for collection" do
    it do
      twin = Twin::Album.new(album)

      expect(twin.songs.size).must_equal 1
      expect(twin.songs[0].title).must_equal "Broken"
      expect(twin.songs).must_be_instance_of Disposable::Twin::Collection

    end
  end

  describe "#find_by" do
    let (:album) { Model::Album.new(1, "The Rest Is Silence", [Model::Song.new(3), Model::Song.new(4)]) }
    let (:twin) { Twin::Album.new(album) }

    it { expect(twin.songs.find_by(id: 1)).must_be_nil }
    it { expect(twin.songs.find_by(id: 3)).must_equal twin.songs[0] }
    it { expect(twin.songs.find_by(id: 4)).must_equal twin.songs[1] }
    it { expect(twin.songs.find_by(id: "4")).must_equal twin.songs[1] }
  end
end

require "disposable/twin/sync"
require "disposable/twin/save"

class TwinCollectionActiveRecordTest < MiniTest::Spec
  module Twin
    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :title

      # property :persisted?, readonly: true # TODO: implement that!!!! for #sync

      include Sync
      include Save
    end

    class Artist < Disposable::Twin
    end

    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      collection :songs, twin: Twin::Song
      property :artist, twin: Twin::Artist

      include Sync
      include Save
      include Setup
      include Collection::Semantics
    end
  end

  let (:album) { Album.create(name: "The Rest Is Silence") }
  let (:song1) { Song.new(title: "Snorty Pacifical Rascal") } # unsaved.
  let (:song2) { Song.create(title: "At Any Cost") } # saved.
  let (:twin) { Twin::Album.new(album) }

  it do
    # TODO: test all writers.
    twin.songs << song1 # assuming that we add AR model here.
    twin.songs << song2

    expect(twin.songs.size).must_equal 2

    expect(twin.songs[0]).must_be_instance_of Twin::Song # twin wraps << added in twin.
    expect(twin.songs[1]).must_be_instance_of Twin::Song

    # expect(twin.songs[0].persisted?).must_equal false
    expect(twin.songs[0].send(:model).persisted?).must_equal false
    expect(twin.songs[1].send(:model).persisted?).must_equal true

    expect(album.songs.size).must_equal 0 # nothing synced, yet.

    # sync: delete removed items, add new?

    # save
    twin.save

    expect(album.persisted?).must_equal true
    expect(album.name).must_equal "The Rest Is Silence"

    expect(album.songs.size).must_equal 2 # synced!

    expect(album.songs[0].persisted?).must_equal true
    expect(album.songs[1].persisted?).must_equal true
    expect(album.songs[0].title).must_equal "Snorty Pacifical Rascal"
    expect(album.songs[1].title).must_equal "At Any Cost"
  end

  # test with adding to existing collection [song1] << song2

  # TODO: #delete non-existent twin.
  describe "#delete" do
    let (:album) { Album.create(name: "The Rest Is Silence", songs: [song1]) }

    it do
      twin.songs.delete(twin.songs.first)

      expect(twin.songs.size).must_equal 0
      expect(album.songs.size).must_equal 1 # not synced, yet.

      twin.save

      expect(twin.songs.size).must_equal 0
      expect(album.songs.size).must_equal 0
      expect(song1.persisted?).must_equal true
    end

    # non-existant delete.
    it do
      twin.songs.delete("non-existant") # won't delete anything.
      expect(twin.songs.size).must_equal 1
    end
  end

  describe "#destroy" do
    let (:album) { Album.create(name: "The Rest Is Silence", songs: [song1]) }

    it do
      twin.songs.destroy(twin.songs.first)

      expect(twin.songs.size).must_equal 0
      expect(album.songs.size).must_equal 1 # not synced, yet.

      twin.save

      expect(twin.songs.size).must_equal 0
      expect(album.songs.size).must_equal 0
      expect(song1.persisted?).must_equal false
    end
  end


  describe "#added" do
    let (:album) { Album.create(name: "The Rest Is Silence", songs: [song1]) }

    it do
      twin = Twin::Album.new(album)

      expect(twin.songs.added).must_equal []
      twin.songs << song2
      expect(twin.songs.added).must_equal [twin.songs[1]]
      twin.songs.insert(2, Song.new)
      expect(twin.songs.added).must_equal [twin.songs[1], twin.songs[2]]

      # TODO: what to do if we override an item (insert)?
    end
  end

  describe "#deleted" do
    let (:album) { Album.create(name: "The Rest Is Silence", songs: [song1, song2, Song.new]) }

    it do
      twin = Twin::Album.new(album)

      expect(twin.songs.deleted).must_equal []

      twin.songs.delete(deleted1 = twin.songs[-1])
      twin.songs.delete(deleted2 = twin.songs[-1])

      expect(twin.songs).must_equal [twin.songs[0]]

      expect(twin.songs.deleted).must_equal [deleted1, deleted2]
    end

    # non-existant delete.
    it do
      twin.songs.delete("non-existant") # won't delete anything.
      expect(twin.songs.deleted).must_equal []
    end
  end
end


class CollectionUnitTest < MiniTest::Spec
  module Twin
    class Album < Disposable::Twin
    end

    class Song < Disposable::Twin
      property :album, twin: Twin::Album
    end
  end

  module Model
    Album = Struct.new(:id, :name, :songs, :artist)
  end

  # THIS is why private tests suck!
  let(:collection) { Disposable::Twin::Collection.new(Disposable::Twin::Twinner.new(Twin::Song.new(OpenStruct.new), Twin::Song.definitions.get(:album)), []) }

  # #insert(index, model)
  it do
    expect(collection.insert(0, Model::Album.new)).must_be_instance_of Twin::Album
  end

  # #append(model)
  it do
    expect(collection.append(Model::Album.new)).must_be_instance_of Twin::Album
    expect(collection[0]).must_be_instance_of Twin::Album

    # allows subsequent calls.
    collection.append(Model::Album.new)
    expect(collection[1]).must_be_instance_of Twin::Album

    expect(collection.size).must_equal 2
  end

  # #<<
  it do
    expect((collection << Model::Album.new)).must_be_instance_of Array
    expect(collection[0]).must_be_instance_of Twin::Album
  end
end
