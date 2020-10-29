require 'test_helper'

# Disposable::Twin::Composition.
class TwinCompositionTest < MiniTest::Spec
  class Request < Disposable::Twin
    include Sync
    include Save
    include Composition

    property :song_title, on: :song, from: :title
    property :song_id,    on: :song, from: :id

    property :name,       on: :requester
    property :id,         on: :requester
    property :captcha,    readable: false, writeable: false, on: :requester # TODO: allow both, virtual with and without :on.
  end

  module Model
    Song      = Struct.new(:id, :title, :album)
    Requester = Struct.new(:id, :name)
  end

  let (:requester) { Model::Requester.new(1, "Greg Howe").extend(Disposable::Saveable) }
  let (:song) { Model::Song.new(2, "Extraction").extend(Disposable::Saveable) }

  let (:request) { Request.new(song: song, requester: requester) }

  it do
    expect(request.song_title).must_equal "Extraction"
    expect(request.song_id).must_equal 2
    expect(request.name).must_equal "Greg Howe"
    expect(request.id).must_equal 1

    request.song_title = "Tease"
    request.name = "Wooten"


    expect(request.song_title).must_equal "Tease"
    expect(request.name).must_equal "Wooten"

    # does not write to model.
    expect(song.title).must_equal "Extraction"
    expect(requester.name).must_equal "Greg Howe"


    res = request.save
    expect(res).must_equal true

    # make sure models got synced and saved.
    expect(song.id).must_equal 2
    expect(song.title).must_equal "Tease"
    expect(requester.id).must_equal 1
    expect(requester.name).must_equal "Wooten"

    expect(song.saved?).must_equal true
    expect(requester.saved?).must_equal true
  end

  # save with block.
  it do
    request.song_title = "Tease"
    request.name = "Wooten"
    request.captcha = "Awesome!"

    # does not write to model.
    expect(song.title).must_equal "Extraction"
    expect(requester.name).must_equal "Greg Howe"


    nested_hash = nil
    request.save do |hash|
      nested_hash = hash
    end

    expect(nested_hash).must_equal(:song=>{"title"=>"Tease", "id"=>2}, :requester=>{"name"=>"Wooten", "id"=>1, "captcha"=>"Awesome!"})
  end

  # save with one unsaveable model.
    #save returns result.
  it do
    song.instance_eval { def save; false; end }
    expect(request.save).must_equal false
  end
end
