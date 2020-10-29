require 'test_helper'

require 'roar/json/collection'
require 'roar/client'

class JsonCollectionTest < MiniTest::Spec
  class Band < OpenStruct; end

  class BandRepresenter < Roar::Decorator
    include Roar::JSON

    property :name
    property :label
  end

  class BandsRepresenter < Roar::Decorator
    include Roar::JSON::Collection
    include Roar::Client

    items extend: BandRepresenter, class: Band
  end

  class Bands < Array
    include Roar::JSON::Collection
  end

  let(:bands) { Bands.new }

  # "[{\"name\":\"Slayer\",\"label\":\"Canadian Maple\"},{\"name\":\"Nirvana\",\"label\":\"Sub Pop\"}])"
  it 'fetches lonely collection of existing bands' do
    BandsRepresenter.new(bands).get(uri: 'http://localhost:4567/bands', as: 'application/json')
    bands.size.must_equal(2)
    bands[0].name.must_equal('Slayer')
  end
end
