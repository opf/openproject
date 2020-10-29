require "test_helper"
require "disposable/expose"
require "disposable/composition"

# Disposable::Expose.
class ExposeTest < MiniTest::Spec
  module Model
    Album = Struct.new(:id, :name)
  end

  module Twin
    class Album < Disposable::Twin
      property :id
      property :title, from: :name
    end
  end

  class AlbumExpose < Disposable::Expose
    from Twin::Album.definitions.values
  end

  let (:album) { Model::Album.new(1, "Dick Sandwich") }
  subject { AlbumExpose.new(album) }

  describe "readers" do
    it  do
      expect(subject.id).must_equal 1
      expect(subject.title).must_equal "Dick Sandwich"
    end
  end


  describe "writers" do
    it do
      subject.id = 3
      subject.title = "Eclipse"

      expect(subject.id).must_equal 3
      expect(subject.title).must_equal "Eclipse"
      expect(album.id).must_equal 3
      expect(album.name).must_equal "Eclipse"
    end
  end
end


# Disposable::Composition.
class ExposeCompositionTest < MiniTest::Spec
  module Model
    Band  = Struct.new(:id)
    Album = Struct.new(:id, :name)
  end

  module Twin
    class Album < Disposable::Twin
      property :id,                 on: :album
      property :name,               on: :album
      property :band_id, from: :id, on: :band
    end

    class AlbumComposition < Disposable::Composition
      from Twin::Album.definitions.values
    end
  end

  let (:band) { Model::Band.new(1) }
  let (:album) { Model::Album.new(2, "Dick Sandwich") }
  subject { Twin::AlbumComposition.new(album: album, band: band) }


  describe "readers" do
    it { expect(subject.id).must_equal 2 }
    it { expect(subject.band_id).must_equal 1 }
    it { expect(subject.name).must_equal "Dick Sandwich" }
  end


  describe "writers" do
    it do
      subject.id = 3
      subject.band_id = 4
      subject.name = "Eclipse"

      expect(subject.id).must_equal 3
      expect(subject.band_id).must_equal 4
      expect(subject.name).must_equal "Eclipse"
      expect(band.id).must_equal 4
      expect(album.id).must_equal 3
      expect(album.name).must_equal "Eclipse"
    end
  end
end
