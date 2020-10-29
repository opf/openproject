require "test_helper"
require "disposable/twin/property/hash"

class HashTest < MiniTest::Spec
  Model = Struct.new(:id, :content)

  class Song < Disposable::Twin
    feature Sync
    include Property::Hash

    property :id
    property :content, field: :hash do
      property :title
      property :band do
        property :name

        property :label do
          property :location
        end
      end

      collection :releases do
        property :version
      end
    end
  end

  # puts Song.definitions.get(:content)[:nested].definitions.get(:band).inspect

  it "allows reading from existing hash" do
    model = Model.new(1, {})
    expect(model.inspect).must_equal "#<struct HashTest::Model id=1, content={}>"

    song = Song.new(model)
    expect(song.id).must_equal 1
    expect(song.content.title).must_be_nil
    expect(song.content.band.name).must_be_nil
    expect(song.content.band.label.location).must_be_nil
    expect(song.content.releases).must_equal []

    # model's hash hasn't changed.
    expect(model.inspect).must_equal "#<struct HashTest::Model id=1, content={}>"
  end

  it "defaults to hash when value is nil" do
    model = Model.new(1)
    expect(model.inspect).must_equal "#<struct HashTest::Model id=1, content=nil>"

    song = Song.new(model)
    expect(song.id).must_equal 1
    expect(song.content.title).must_be_nil
    expect(song.content.band.name).must_be_nil
    expect(song.content.band.label.location).must_be_nil

    # model's hash hasn't changed.
    expect(model.inspect).must_equal "#<struct HashTest::Model id=1, content=nil>"
  end

  it "#sync writes to model" do
    model = Model.new

    song = Song.new(model)
    song.content.band.label.location = "San Francisco"

    song.sync

    expect(model.inspect).must_equal "#<struct HashTest::Model id=nil, content={\"band\"=>{\"label\"=>{\"location\"=>\"San Francisco\"}}, \"releases\"=>[]}>"
  end

  it "#appends to collections" do
    model = Model.new

    song = Song.new(model)
    # song.content.releases.append(version: 1) # FIXME: yes, this happens!
    song.content.releases.append("version" => 1)

    song.sync

    expect(model.inspect).must_equal "#<struct HashTest::Model id=nil, content={\"band\"=>{\"label\"=>{}}, \"releases\"=>[{\"version\"=>1}]}>"
  end

  it "doesn't erase existing, undeclared content" do
    model = Model.new(nil, {"artist"=>{}})

    song = Song.new(model)
    song.content.band.label.location = "San Francisco"

    # puts song.content.class.ancestors
    song.sync

    expect(model.inspect).must_equal "#<struct HashTest::Model id=nil, content={\"artist\"=>{}, \"band\"=>{\"label\"=>{\"location\"=>\"San Francisco\"}}, \"releases\"=>[]}>"
  end

  it "doesn't erase existing, undeclared content in existing content" do
    model = Model.new(nil, {"band"=>{ "label" => { "owner" => "Brett Gurewitz" }, "genre" => "Punkrock" }})

    song = Song.new(model)
    song.content.band.label.location = "San Francisco"

    song.sync

    expect(model.inspect).must_equal "#<struct HashTest::Model id=nil, content={\"band\"=>{\"label\"=>{\"owner\"=>\"Brett Gurewitz\", \"location\"=>\"San Francisco\"}, \"genre\"=>\"Punkrock\"}, \"releases\"=>[]}>"
  end


  describe "features propagation" do
    module UUID
      def uuid
        "1224"
      end
    end

    class Hit < Disposable::Twin
      include Property::Hash
      feature UUID

      property :id
      property :content, field: :hash do
        property :title
        property :band do
          property :name
        end
      end
    end

    it "includes features into all nested twins" do
      song = Hit.new(Model.new)
      expect(song.uuid).must_equal "1224"
      expect(song.content.uuid).must_equal "1224"
      expect(song.content.band.uuid).must_equal "1224"
    end
  end

  describe "coercion" do
    require "disposable/twin/coercion"
    class Coercing < Disposable::Twin
      include Property::Hash
      feature Coercion

      property :id, type: const_get("Types::Coercible::#{DRY_TYPES_INT_CONSTANT}")
      property :content, field: :hash do
        property :title
        property :band do
          property :name, type: Types::Coercible::String
        end
      end
    end

    it "coerces" do
      song = Coercing.new(Model.new(1))
      song.id = "9"
      expect(song.id).must_equal 9
      song.content.band.name = 18
      expect(song.content.band.name).must_equal "18"
    end
  end

  describe "::unnest" do
    class Unnesting < Disposable::Twin
      feature Sync
      include Property::Hash

      property :id
      property :content, field: :hash do
        property :title
        property :band do
          property :name

          property :label do
            property :location
          end
        end

        collection :releases do
          property :version
        end
      end

      unnest :title, from: :content
      unnest :band,  from: :content
      # property :title, virtual: true#, _inherit: true, nested: content[:nested].definitions.get(:title)[:nested]
      # def title=(v)
      #   raise v.inspect
      #   content.title=(v)
      # end
    end

    it "exposes reader and writer" do
      model = Model.new(1, {title: "Bedroom Eyes"})
      song = Unnesting.new(model)

      # singular scalar accessors
      expect(song.content.title).must_equal "Bedroom Eyes"
      expect(song.title).must_equal "Bedroom Eyes"

      song.title = "Notorious"
      expect(song.title).must_equal "Notorious"
      expect(song.content.title).must_equal "Notorious"

      # singular nested accessors
      expect(song.band.name).must_be_nil
      expect(song.content.band.name).must_be_nil
      song.band.name = "Duran Duran"
      expect(song.band.name).must_equal "Duran Duran"
    end
  end

  describe 'collection schema' do
    AlbumModel = Struct.new(:id, :songs)
    class Album < Disposable::Twin
      feature Sync
      feature Property::Hash

      property :id
      collection :songs, field: :hash do
        property :title
        property :band do
          property :name

          property :label do
            property :location
          end
        end

        collection :featured_artists do
          property :name
        end
      end
    end

    it "exposes reader and writer" do
      model = AlbumModel.new(1, [
        { title: "Sherry", band: { name: 'The Four Seasons', label: { location: 'US' } }, featured_artists: [{ name: 'Frankie Valli' }, { name: 'The Variatones' }] },
        { title: "Walk Like a Man", band: { name: 'The Four Seasons', label: { location: 'US' } }, featured_artists: [{ name: 'Frankie Valli' }] }
      ])
      contract = Album.new(model)

      song1 = contract.songs[0]

      expect(song1.title).must_equal "Sherry"
      expect(song1.band.name).must_equal 'The Four Seasons'
      expect(song1.band.label.location).must_equal 'US'
      expect(song1.featured_artists[0].name).must_equal 'Frankie Valli'
      expect(song1.featured_artists[1].name).must_equal 'The Variatones'

      song2 = contract.songs[1]

      expect(song2.title).must_equal "Walk Like a Man"
      expect(song2.band.name).must_equal 'The Four Seasons'
      expect(song2.band.label.location).must_equal 'US'
      expect(song2.featured_artists[0].name).must_equal 'Frankie Valli'
    end
  end
end

# fixme: make sure default hash is different for every invocation, and not created at compile time.

# TODO: test that config is same and nested.
