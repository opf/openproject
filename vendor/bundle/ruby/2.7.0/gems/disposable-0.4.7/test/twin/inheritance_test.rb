require "test_helper"

class InheritanceTest < Minitest::Spec
  let (:song) { OpenStruct.new(id: 0) }

  module Id
    def id
      super - 1
    end

    def id=(v)
      super(v+1)
    end
  end

  class Twin < Disposable::Twin
    property :id
    include Id
  end

  it do
    twin = Twin.new(song)
    expect(twin.id).must_equal 0
  end

  class TwinComposition < Disposable::Twin
    include Composition

    property :id, on: :song
    include Id
  end

  it do
    twin = TwinComposition.new(song: song)
    expect(twin.id).must_equal 0
    twin.id= 3
    expect(twin.id).must_equal 3
  end


  class TwinCompositionDefineMethod < Disposable::Twin
    include Composition

    property :id, on: :song

    define_method :id do
      super() + 9
    end
  end

  it do
    twin = TwinCompositionDefineMethod.new(song: song)
    expect(twin.id).must_equal 9
  end


  describe ":from" do
    let (:song) { Struct.new(:ident).new(1) }

    class TwinWithFrom < Disposable::Twin
      include Expose
      property :id, from: :ident
    end

    class InheritingFrom < TwinWithFrom
    end

    it do
      expect(TwinWithFrom.new(song).id).must_equal 1
      expect(InheritingFrom.new(song).id).must_equal 1
    end
  end
end
