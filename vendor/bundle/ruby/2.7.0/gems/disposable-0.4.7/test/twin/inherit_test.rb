require "test_helper"

class InheritTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:title, :album)
    Album = Struct.new(:name, :songs, :artist)
    Artist = Struct.new(:name)
  end

  module Twin
    class Album < Disposable::Twin
      feature Setup

      property :name, fromage: :_name

      collection :songs do
        property :name
      end

      property :artist do
        property :name

        def artist_id
          1
        end
      end
    end

    class EmptyCompilation < Album
    end

    class Compilation < Album
      property :name, writeable: false, inherit: true

      property :artist, inherit: true do

      end
    end
  end

  # definitions are not shared.
  it do
    expect(Twin::Album.definitions.get(:name).extend(Declarative::Inspect).inspect).must_equal "#<Disposable::Twin::Definition: @options={:fromage=>:_name, :private_name=>:name, :name=>\"name\"}>"
    expect(Twin::Compilation.definitions.get(:name).extend(Declarative::Inspect).inspect).must_equal "#<Disposable::Twin::Definition: @options={:fromage=>:_name, :private_name=>:name, :name=>\"name\", :writeable=>false}>" # FIXME: where did :inherit go?
  end


  let (:album) { Model::Album.new("In The Meantime And Inbetween Time", [], Model::Artist.new) }

  it { expect(Twin::Album.new(album).artist.artist_id).must_equal 1 }

  # inherit inline twins when not overriding.
  it { expect(Twin::EmptyCompilation.new(album).artist.artist_id).must_equal 1 }

  # inherit inline twins when overriding.
  it { expect(Twin::Compilation.new(album).artist.artist_id).must_equal 1 }

  describe "custom accessors get inherited" do
    class Singer < Disposable::Twin
      property :name

      def name
        super.reverse
      end

      def name=(val)
        super(val.downcase)
      end
    end

    class Star < Singer
    end

    let (:model) { Model::Artist.new("Helloween") }

    it do
      artist = Star.new(model)
      expect(artist.name).must_equal("neewolleh")

      artist.name = "HELLOWEEN"
      # artist.with_custom_setter = "this gets ignored"
      expect(artist.name).must_equal("neewolleh")
    end
  end
end
