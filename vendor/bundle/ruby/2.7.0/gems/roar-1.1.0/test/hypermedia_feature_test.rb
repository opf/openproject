  require 'test_helper'

class HypermediaTest < MiniTest::Spec

  describe "Hypermedia Feature" do

    let (:song) { Song.new(:title => "Brandy Wine") }

    before do
      @bookmarks = Class.new do
        include AttributesConstructor
        include Roar::XML
        include Roar::Hypermedia

        self.representation_wrap = "bookmarks"
      end

      @bookmarks_with_links = Class.new(@bookmarks)
      @bookmarks_with_links.class_eval do
        self.representation_wrap = "bookmarks"

        property :id
        link :self do "http://bookmarks" end
        link :all do "http://bookmarks/all" end

        attr_accessor :id, :self, :all
      end
    end


    describe "#to_xml" do
      it "works when no links defined" do
        decorator_class = Class.new(Roar::Decorator) do
          include Roar::XML
          include Roar::Hypermedia

          self.representation_wrap = "song"
          property :title
        end

        decorator_class.new(song).to_xml.must_equal_xml "<song><title>Brandy Wine</title></song>"
      end

      let(:decorator_class) { Class.new(Roar::Decorator) do
        include Roar::XML
        include Roar::Hypermedia

        self.representation_wrap = "song"
        property :title

        link(:self) { "/songs/#{represented.title}" }
        link(:all) { "/songs" }
      end }

      it "includes links in rendered document" do
        decorator_class.new(song).to_xml.must_equal_xml %{
          <song>
            <title>Brandy Wine</title>
            <link rel="self" href="/songs/Brandy Wine"/>
            <link rel="all" href="/songs"/>
          </song>}
      end

      it "suppresses links when links: false" do
        decorator_class.new(song).to_xml(user_options: {links: false}).must_equal_xml "<song><title>Brandy Wine</title></song>"
      end

      it "renders nested links" do
        song_decorator_class  = decorator_class
        album_decorator_class = Class.new(Roar::Decorator) do
          include Roar::XML
          include Roar::Hypermedia

          self.representation_wrap = "album"
          collection :songs, :extend => song_decorator_class

          link(:self) { "/albums/mixed" }
        end

        album_decorator_class.new(Album.new(:songs => [song])).to_xml.must_equal_xml %{
          <album>
            <song>
              <title>Brandy Wine</title>
              <link rel="self" href="/songs/Brandy Wine"/>
              <link rel="all" href="/songs"/>
            </song>
            <link rel="self" href="/albums/mixed"/>
          </album>
        }
      end
    end

    describe "#to_json" do
      class Note
        include Roar::JSON
        include Roar::Hypermedia
        link(:self) { "http://me" }
      end

      it "works twice" do
        note = Note.new
        assert_equal note.to_json, note.to_json
      end

      it "sets up links even when nested" do
        class Page
          include AttributesConstructor
          include Roar::JSON
          property :note, :class => Note
          attr_accessor :note
        end

        assert_equal "{\"note\":{\"links\":[{\"rel\":\"self\",\"href\":\"http://me\"}]}}", Page.new(:note => Note.new).to_json
      end
    end



    describe "#from_xml" do
      it "extracts links from document" do
        doc = @bookmarks_with_links.new.from_xml(%{
        <bookmarks>
          <link rel="self" href="http://bookmarks">
        </bookmarks>
        })

        assert_kind_of Hash, doc.links
        assert_equal 1, doc.links.size
        assert_equal(["self", "http://bookmarks"], [doc.links["self"].rel, doc.links["self"].href])
      end

      it "sets up an empty link list if no links found in the document" do
        @bookmarks_with_links.new.from_xml(%{<bookmarks/>}).links.must_equal({})
      end
    end
  end
end
