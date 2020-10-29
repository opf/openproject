require "test_helper"
require "disposable/callback"

class CallbacksTest < MiniTest::Spec
  before do
    @invokes = []
  end

  attr_reader :invokes

  class AlbumTwin < Disposable::Twin
    feature Sync, Save
    feature Persisted, Changed

    property :name

    property :artist do
      # on_added
      # on_removed
      property :name
    end

    collection :songs do
      # after_add: could also be existing user
      # after_remove
      # after_create: this means added+changed?(:persisted): song created and added.
      # after_update
      property :title
    end
  end

  # - Callbacks don't have before and after. This is up to the caller.
  Callback = Disposable::Callback::Dispatch
    # collection :songs do
    #   after_add    :song_added! # , context: :operation
    #   after_create :notify_album!
    #   after_remove :notify_artist!
    # end

  let (:twin) { AlbumTwin.new(album) }

  describe "#on_create" do
    let (:album) { Album.new }

    # after initialization
    it do
      invokes = []
      Callback.new(twin).on_create { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # save, without any attributes changed.
    it do
      twin.save

      invokes = []
      Callback.new(twin).on_create { |t| invokes << t }
      expect(invokes).must_equal [twin]
    end

    # before and after save, with attributes changed
    it do
      # state change, but not persisted, yet.
      twin.name = "Run For Cover"
      invokes = []
      Callback.new(twin).on_create { |t| invokes << t }
      expect(invokes).must_equal []

      twin.save

      Callback.new(twin).on_create { |t| invokes << t }
      expect(invokes).must_equal [twin]
    end

    # for collections.
    it do
      album.songs << Song.new
      album.songs << Song.create(title: "Run For Cover")
      album.songs << Song.new
      invokes = []

      Callback.new(twin.songs).on_create { |t| invokes << t }
      expect(invokes).must_equal []

      twin.save

      Callback.new(twin.songs).on_create { |t| invokes << t }
      expect(invokes).must_equal [twin.songs[0], twin.songs[2]]
    end
  end

  describe "#on_update" do
    let (:album) { Album.new }

    # after initialization.
    it do
      invokes = []
      Callback.new(twin).on_update { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # single twin.
    # on_update only works on persisted objects.
    it do
      twin.name = "After The War" # change but not persisted

      invokes = []
      Callback.new(twin).on_update { |t| invokes << t }
      expect(invokes).must_equal []

      invokes = []
      twin.save

      Callback.new(twin).on_update { |t| invokes << t }
      expect(invokes).must_equal []


      # now with the persisted album.
      twin = AlbumTwin.new(album) # Album is persisted now.

      Callback.new(twin).on_update { |t| invokes << t }
      expect(invokes).must_equal []

      invokes = []
      twin.save

      # nothing has changed, yet.
      Callback.new(twin).on_update { |t| invokes << t }
      expect(invokes).must_equal []

      twin.name= "Corridors Of Power"

      # this will even trigger on_update before saving.
      Callback.new(twin).on_update { |t| invokes << t }
      expect(invokes).must_equal [twin]

      invokes = []
      twin.save

      # name changed.
      Callback.new(twin).on_update { |t| invokes << t }
      expect(invokes).must_equal [twin]
    end

    # for collections.
    it do
      album.songs << Song.new
      album.songs << Song.create(title: "Run For Cover")
      album.songs << Song.new

      invokes = []
      Callback.new(twin.songs).on_update { |t| invokes << t }
      expect(invokes).must_equal []

      invokes = []
      twin.save

      # initial save is no update.
      Callback.new(twin.songs).on_update { |t| invokes << t }
      expect(invokes).must_equal []


      # now with the persisted album.
      twin = AlbumTwin.new(album) # Album is persisted now.

      Callback.new(twin.songs).on_update { |t| invokes << t }
      expect(invokes).must_equal []

      invokes = []
      twin.save

      # nothing has changed, yet.
      Callback.new(twin.songs).on_update { |t| invokes << t }
      expect(invokes).must_equal []

      twin.songs[1].title= "After The War"
      twin.songs[2].title= "Run For Cover"

      # # this will even trigger on_update before saving.
      Callback.new(twin.songs).on_update { |t| invokes << t }
      expect(invokes).must_equal [twin.songs[1], twin.songs[2]]

      invokes = []
      twin.save

      Callback.new(twin.songs).on_update { |t| invokes << t }
      expect(invokes).must_equal [twin.songs[1], twin.songs[2]]
    end
    # it do
    #   album.songs << song1 = Song.new
    #   album.songs << Song.create(title: "Run For Cover")
    #   album.songs << song2 = Song.new
    #   invokes = []

    #   Callback.new(twin.songs).on_create { |t| invokes << t }
    #   invokes.must_equal []

    #   twin.save

    #   Callback.new(twin.songs).on_create { |t| invokes << t }
    #   invokes.must_equal [twin.songs[0], twin.songs[2]]
    # end
  end


  describe "#on_add" do
    let (:album) { Album.new }

    # empty collection.
    it do
      invokes = []
      Callback.new(twin.songs).on_add { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # collection present on initialize are not added.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song, song]

      Callback.new(twin.songs).on_add { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # items added after initialization are added.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song]

      twin.songs << song

      Callback.new(twin.songs).on_add { |t| invokes << t }
      expect(invokes).must_equal [twin.songs[1]]

      twin.save

      # still shows the added after save.
      invokes = []
      Callback.new(twin.songs).on_add { |t| invokes << t }
      expect(invokes).must_equal [twin.songs[1]]
    end
  end

  describe "#on_add(:created)" do
    let (:album) { Album.new }

    # empty collection.
    it do
      invokes = []
      Callback.new(twin.songs).on_add(:created) { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # collection present on initialize are not added.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song, song]

      Callback.new(twin.songs).on_add(:created) { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # items added after initialization are added.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song]

      twin.songs << song
      twin.songs << ex_song # already created.

      Callback.new(twin.songs).on_add(:created) { |t| invokes << t }
      expect(invokes).must_equal []

      twin.save

      # still shows the added after save.
      invokes = []
      Callback.new(twin.songs).on_add(:created) { |t| invokes << t }
      expect(invokes).must_equal [twin.songs[1]] # only the created is invoked.
    end
  end

  describe "#on_delete" do
    let (:album) { Album.new }

    # empty collection.
    it do
      invokes = []
      Callback.new(twin.songs).on_delete { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # collection present but nothing deleted.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song, song]

      Callback.new(twin.songs).on_delete { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # items deleted.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song, song]

      twin.songs.delete(deleted = twin.songs[0])

      Callback.new(twin.songs).on_delete { |t| invokes << t }
      expect(invokes).must_equal [deleted]

      twin.save

      # still shows the deleted after save.
      invokes = []
      Callback.new(twin.songs).on_delete { |t| invokes << t }
      expect(invokes).must_equal [deleted]
    end
  end

  describe "#on_destroy" do
    let (:album) { Album.new }

    # empty collection.
    it do
      invokes = []
      Callback.new(twin.songs).on_destroy { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # collection present but nothing deleted.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song, song]

      Callback.new(twin.songs).on_destroy { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # items deleted, doesn't trigger on_destroy.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song, song]

      twin.songs.delete(twin.songs[0])

      Callback.new(twin.songs).on_destroy { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # items destroyed.
    it do
      ex_song = Song.create(title: "Run For Cover")
      song    = Song.new
      album.songs = [ex_song, song]

      twin.songs.destroy(deleted = twin.songs[0])

      Callback.new(twin.songs).on_destroy { |t| invokes << t }
      expect(invokes).must_equal []

      twin.extend(Disposable::Twin::Collection::Semantics) # now #save will destroy.
      twin.save

      # still shows the deleted after save.
      invokes = []
      Callback.new(twin.songs).on_destroy { |t| invokes << t }
      expect(invokes).must_equal [deleted]
    end
  end


  describe "#on_change" do
    let (:album) { Album.new }

    # after initialization
    it do
      Callback.new(twin).on_change { |t| invokes << t }
      expect(invokes).must_equal []
    end

    # save, without any attributes changed. unpersisted before.
    it do
      twin = AlbumTwin.new(Album.create)

      twin.save

      Callback.new(twin).on_change { |t| invokes << t }
      expect(invokes).must_equal [] # nothing has changed, not even persisted?.
    end

    # save, without any attributes changed. persisted before.
    it do
      twin.save

      Callback.new(twin).on_change { |t| invokes << t }
      expect(invokes).must_equal [twin]
    end

    # before and after save, with attributes changed
    it do
      # state change, but not persisted, yet.
      twin.name = "Run For Cover"
      invokes = []
      Callback.new(twin).on_change { |t| invokes << t }
      expect(invokes).must_equal [twin]

      twin.save

      invokes = []
      Callback.new(twin).on_change { |t| invokes << t }
      expect(invokes).must_equal [twin]
    end

    # for scalars: on_change(:email).
    it do
      Callback.new(twin).on_change(property: :name) { |t| invokes << t }
      expect(invokes).must_equal []

      twin.name = "Unforgiven"

      Callback.new(twin).on_change(property: :name) { |t| invokes << t }
      expect(invokes).must_equal [twin]
    end

    # for collections.
    # it do
    #   album.songs << song1 = Song.new
    #   album.songs << Song.create(title: "Run For Cover")
    #   album.songs << song2 = Song.new
    #   invokes = []

    #   Callback.new(twin.songs).on_change { |t| invokes << t }
    #   invokes.must_equal []

    #   twin.save

    #   Callback.new(twin.songs).on_change { |t| invokes << t }
    #   invokes.must_equal [twin.songs[0], twin.songs[2]]
    # end
  end
end
