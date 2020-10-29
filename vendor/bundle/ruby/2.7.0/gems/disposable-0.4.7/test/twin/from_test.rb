require 'test_helper'

class FromTest < MiniTest::Spec
  module Model
    Album = Struct.new(:name, :composer)
    Artist = Struct.new(:realname)
  end


  module Twin
    class Album < Disposable::Twin
      feature Sync
      feature Save
      feature Disposable::Twin::Expose

      property :full_name, from: :name

      property :artist, from: :composer do
        property :name, from: :realname
      end
    end
  end


  let (:composer) { Model::Artist.new("AFI").extend(Disposable::Saveable) }
  let (:album)    { Model::Album.new("Black Sails In The Sunset", composer).extend(Disposable::Saveable) }
  let (:twin)     { Twin::Album.new(album) }

  it do
    expect(twin.full_name).must_equal "Black Sails In The Sunset"
    expect(twin.artist.name).must_equal "AFI"

    twin.save


  end
end
