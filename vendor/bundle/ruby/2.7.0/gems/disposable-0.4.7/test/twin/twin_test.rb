require 'test_helper'

class TwinTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs, :artist)
    Artist = Struct.new(:id)
  end

  # test twin: option
  module Twin
    class Artist < Disposable::Twin
      property :id

      include Setup
    end

    class Album < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :name
      property :artist, twin: Artist
    end

    class Song < Disposable::Twin
      property :id # DISCUSS: needed for #save.
      property :title
      property :album, twin: Album
    end
  end

  let (:song) { Model::Song.new(1, "Broken", nil) }

  describe "#initialize" do
    it do
      twin = Twin::Song.new(song)
      song.id = 2
      # :from maps public name
      expect(twin.title).must_equal "Broken" # public: #record_name
      expect(twin.id).must_equal 1
    end

    # allows passing options.
    it do
      # override twin's value...
      expect(Twin::Song.new(song, :title => "Kenny").title).must_equal "Kenny"

      # .. but do not write to the model!
      expect(song.title).must_equal "Broken"
    end
  end

  describe "setter" do
    let (:twin) { Twin::Song.new(song) }
    let (:album) { Model::Album.new(1, "The Stories Are True") }

    it do
      twin.id = 3
      twin.title = "Lucky"
      twin.album = album # this is a model, not a twin.

      # updates twin
      expect(twin.id).must_equal 3
      expect(twin.title).must_equal "Lucky"

      # setter for nested property will twin value.
      twin.album.extend(Disposable::Comparable)
      assert twin.album == Twin::Album.new(album) # FIXME: why does) must_equal not call #== ?

      # setter for nested collection.

      # DOES NOT update model
      expect(song.id).must_equal 1
      expect(song.title).must_equal "Broken"
    end

    describe "deleting" do
      it "allows overwriting nested twin with nil" do
        album = Model::Album.new(1, "Uncertain Terms", [], Model::Artist.new("Greg Howe"))
        twin = Twin::Album.new(album)
        expect(twin.artist.id).must_equal "Greg Howe"

        twin.artist = nil
        expect(twin.artist).must_be_nil
      end
    end

    # setters for twin properties return the twin, not the model
    # it do
    #   result = twin.album = album
    #   result.must_equal twin.album
    # end
  end
end


class OverridingAccessorsTest < TwinTest
  # overriding accessors in Twin
  class Song < Disposable::Twin
    property :title
    property :id

    def title
      super.downcase
    end

    def id=(v)
      super(v+1)
    end
  end

  let (:model) { Model::Song.new(1, "A Tale That Wasn't Right") }
  it { expect(Song.new(model).title).must_equal "a tale that wasn't right" }
  it { expect(Song.new(model).id).must_equal 2 }
end


class TwinAsTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :album)
    Album = Struct.new(:name)
  end


  module Twin
    class Album < Disposable::Twin
      property :record_name, :from => :name

      # model Model::Album
    end

    class Song < Disposable::Twin
      property :name, :from => :title
      property :record, twin: Album, :from => :album

      # model Model::Song
    end
  end

end
# TODO: test coercion!

class AccessorsTest < Minitest::Spec
  Song = Struct.new(:format)

  class Twin < Disposable::Twin
    property :format # Kernel#format
  end

  it do
    twin = Twin.new(Song.new("bla"))
    expect(twin.format).must_equal "bla"
    twin.format = "blubb"
  end
end

class InvalidPropertyNameTest < Minitest::Spec
  it 'raises InvalidPropertyNameError' do
  assert_raises(Disposable::Twin::InvalidPropertyNameError) {
      class Twin < Disposable::Twin
        property :class
      end
    }
  end
end
