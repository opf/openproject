require 'test_helper'

class TwinFromCollectionDecoratorTest < MiniTest::Spec
  module Model
    Artist = Struct.new(:id, :name)
  end

  module Twin
    class Artist < Disposable::Twin
      property :id
      property :name
    end
  end

  let (:artist1) { Model::Artist.new(1, "AFI") }
  let (:artist2) { Model::Artist.new(2, "Gary Moore") }
  let (:collection) { [artist1, artist2] }

  describe "from a collection" do
    it do
      twined_collection = Twin::Artist.from_collection(collection)

      expect(twined_collection[0]).must_be_instance_of Twin::Artist
      expect(twined_collection[0].model).must_equal artist1
      expect(twined_collection[1]).must_be_instance_of Twin::Artist
      expect(twined_collection[1].model).must_equal artist2
    end
  end
end
