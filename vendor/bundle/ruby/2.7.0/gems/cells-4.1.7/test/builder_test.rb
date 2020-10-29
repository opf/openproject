require 'test_helper'

class BuilderTest < MiniTest::Spec
  Song = Struct.new(:title)
  Hit  = Struct.new(:title)

  class SongCell < Cell::ViewModel
    include Cell::Builder

    builds do |model, options|
      if model.is_a? Hit
        HitCell
      elsif options[:evergreen]
        EvergreenCell
      end
    end

    def options
      @options
    end

    def show
      "* #{title}"
    end

    property :title
  end

  class HitCell < SongCell
    def show
      "* **#{title}**"
    end
  end

  class EvergreenCell < SongCell
  end

  # the original class is used when no builder matches.
  it { SongCell.(Song.new("Nation States"), {}).must_be_instance_of SongCell }

  it do
    cell = SongCell.(Hit.new("New York"), {})
    cell.must_be_instance_of HitCell
    cell.options.must_equal({})
  end

  it do
    cell = SongCell.(Song.new("San Francisco"), evergreen: true)
    cell.must_be_instance_of EvergreenCell
    cell.options.must_equal({evergreen:true})
  end

  # without arguments.
  it { SongCell.(Hit.new("Frenzy")).must_be_instance_of HitCell }

  # with collection.
  it { SongCell.(collection: [Song.new("Nation States"), Hit.new("New York")]).().must_equal "* Nation States* **New York**" }

  # with Concept
  class Track < Cell::Concept
  end
  it { Track.().must_be_instance_of Track }
end
