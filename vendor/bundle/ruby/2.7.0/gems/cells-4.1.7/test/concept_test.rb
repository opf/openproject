require 'test_helper'

Cell::Concept.class_eval do
  self.view_paths = ['test/fixtures/concepts']
end

# Trailblazer style:
module Record
  class Cell < ::Cell::Concept # cell("record")
    include ::Cell::Erb

    def show
      render # Party On, #{model}
    end

    # cell(:song, concept: :record)
    class Song < self # cell("record/cell/song")
      def show
        render view: :song#, layout: "layout"
        # TODO: test layout: .. in ViewModel
      end
    end

    class Hit < ::Cell::Concept
      inherit_views Record::Cell
    end


    def description
      "A Tribute To Rancid, with #{@options[:tracks]} songs! [#{context}]"
    end
  end
end

module Record
  module Cells
    class Cell < ::Cell::Concept
      class Song < ::Cell::Concept
      end
    end
  end
end

# app/cells/comment/views
# app/cells/comment/form/views
# app/cells/comment/views/form inherit_views Comment::Cell, render form/show


class ConceptTest < MiniTest::Spec
  describe "::controller_path" do
    it { Record::Cell.new.class.controller_path.must_equal "record" }
    it { Record::Cell::Song.new.class.controller_path.must_equal "record/song" }
    it { Record::Cells::Cell.new.class.controller_path.must_equal "record/cells" }
    it { Record::Cells::Cell::Song.new.class.controller_path.must_equal "record/cells/song" }
  end


  describe "#_prefixes" do
    it { Record::Cell.new._prefixes.must_equal       ["test/fixtures/concepts/record/views"] }
    it { Record::Cell::Song.new._prefixes.must_equal ["test/fixtures/concepts/record/song/views", "test/fixtures/concepts/record/views"] }
    it { Record::Cell::Hit.new._prefixes.must_equal  ["test/fixtures/concepts/record/hit/views", "test/fixtures/concepts/record/views"]  } # with inherit_views.
  end

  it { Record::Cell.new("Wayne").call(:show).must_equal "Party on, Wayne!" }


  describe "::cell" do
    it { Cell::Concept.cell("record/cell").must_be_instance_of(      Record::Cell) }
    it { Cell::Concept.cell("record/cell/song").must_be_instance_of  Record::Cell::Song }
    # cell("song", concept: "record/compilation") # record/compilation/cell/song
  end

  describe "#render" do
    it { Cell::Concept.cell("record/cell/song").show.must_equal "Lalala" }
  end

  describe "#cell (in state)" do
    # test with controller, but remove tests when we don't need it anymore.
    it { Cell::Concept.cell("record/cell", nil, context: { controller: Object }).cell("record/cell", nil).must_be_instance_of Record::Cell }
    it { Cell::Concept.cell("record/cell", nil, context: { controller: Object }).concept("record/cell", nil, tracks: 24).(:description).must_equal "A Tribute To Rancid, with 24 songs! [{:controller=>Object}]" }
    # concept(.., collection: ..)
    it do
      Cell::Concept.cell("record/cell", nil, context: { controller: Object }).
        concept("record/cell", collection: [1,2], tracks: 24).(:description).must_equal "A Tribute To Rancid, with 24 songs! [{:controller=>Object}]A Tribute To Rancid, with 24 songs! [{:controller=>Object}]" 
    end
  end
end
