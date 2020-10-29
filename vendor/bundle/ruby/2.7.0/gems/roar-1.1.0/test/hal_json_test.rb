require 'test_helper'
require 'roar/json/hal'

class HalJsonTest < MiniTest::Spec
  let(:decorator_class) do
    Class.new(Roar::Decorator) do
      include Roar::JSON
      include Roar::JSON::HAL

      links :self do
        [{:lang => "en", :href => "http://en.hit"},
         {:lang => "de", :href => "http://de.hit"}]
      end

      link :next do
        "http://next"
      end
    end
  end

  subject { decorator_class.new(Object.new) }

  describe "links" do
    describe "parsing" do
      it "parses link array" do # TODO: remove me.
        obj = subject.from_json("{\"_links\":{\"self\":[{\"lang\":\"en\",\"href\":\"http://en.hit\"},{\"lang\":\"de\",\"href\":\"http://de.hit\"}]}}")
        subject.links.must_equal "self" => [link("rel" => "self", "href" => "http://en.hit", "lang" => "en"), link("rel" => "self", "href" => "http://de.hit", "lang" => "de")]
      end

      it "parses single links" do # TODO: remove me.
        obj = subject.from_json("{\"_links\":{\"next\":{\"href\":\"http://next\"}}}")
        subject.links.must_equal "next" => link("rel" => "next", "href" => "http://next")
      end

      it "parses link and link array" do
        obj = subject.from_json(%@{"_links":{"next":{"href":"http://next"}, "self":[{"lang":"en","href":"http://en.hit"},{"lang":"de","href":"http://de.hit"}]}}@)
        subject._links.must_equal "next"=>link("rel" => "next", "href" => "http://next"), "self"=>[link("rel" => "self", "href" => "http://en.hit", "lang" => "en"), link("rel" => "self", "href" => "http://de.hit", "lang" => "de")]
      end

      it "parses empty link array" do
        subject.from_json("{\"_links\":{\"self\":[]}}")
        subject.links[:self].must_be_nil
      end

      it "parses non-existent link array" do
        subject.from_json("{\"_links\":{}}")
        subject.links[:self].must_be_nil # DISCUSS: should this be []?
      end

      # it "rejects single links declared as array" do
      #   assert_raises TypeError do
      #     subject.from_json("{\"_links\":{\"self\":{\"href\":\"http://next\"}}}")
      #   end
      # end
    end

    describe "rendering" do
      it "renders link and link array" do
        subject.to_json.must_equal "{\"_links\":{\"self\":[{\"lang\":\"en\",\"href\":\"http://en.hit\"},{\"lang\":\"de\",\"href\":\"http://de.hit\"}],\"next\":{\"href\":\"http://next\"}}}"
      end
    end
  end

  describe "empty link array" do
    let(:decorator_class) do
      Class.new(Roar::Decorator) do
        include Roar::JSON
        include Roar::JSON::HAL

        links(:self) { [] }
      end
    end

    subject { decorator_class.new(Object.new) }

    it "gets render" do
      subject.to_json.must_equal %@{"_links":{"self":[]}}@
    end
  end


  describe "_links and _embedded" do
    let(:decorator_class) do
      Class.new(Roar::Decorator) do
        include Roar::JSON
        include Roar::JSON::HAL

        property :id
        collection :songs, class: Song, embedded: true do
          include Roar::JSON::HAL

          property :title
          link(:self) { "http://songs/#{represented.title}" }
        end

        link(:self) { "http://albums/#{represented.id}" }
      end
    end

    let(:album) { Album.new(:songs => [Song.new(:title => "Beer")], :id => 1) }
    subject { decorator_class.new(album) }

    it "render links and embedded resources according to HAL" do
      subject.to_json.must_equal "{\"id\":1,\"_embedded\":{\"songs\":[{\"title\":\"Beer\",\"_links\":{\"self\":{\"href\":\"http://songs/Beer\"}}}]},\"_links\":{\"self\":{\"href\":\"http://albums/1\"}}}"
    end

    it "parses links and resources following the mighty HAL" do
      subject.from_json("{\"id\":2,\"_embedded\":{\"songs\":[{\"title\":\"Coffee\",\"_links\":{\"self\":{\"href\":\"http://songs/Coffee\"}}}]},\"_links\":{\"self\":{\"href\":\"http://albums/2\"}}}")
      assert_equal 2, album.id
      assert_equal "Coffee", album.songs.first.title
      # FIXME assert_equal "http://songs/Coffee", subject.songs.first.links["self"].href
      assert_equal "http://albums/2", subject.links["self"].href
    end

    it "doesn't require _links and _embedded to be present" do
      subject.from_json("{\"id\":2}")
      assert_equal 2, album.id

      # in newer representables, this is not overwritten to an empty [] anymore.
      assert_equal ["Beer"], album.songs.map(&:title)
      album.links.must_be_nil
    end
  end

end

class JsonHalTest < MiniTest::Spec
  Album  = Struct.new(:artist, :songs)
  Artist = Struct.new(:name)
  Song = Struct.new(:title)

  describe "render_nil: false" do
    let(:decorator_class) do
      Class.new(Roar::Decorator) do
        include Roar::JSON
        include Roar::JSON::HAL

        property :artist, embedded: true, render_nil: false do
          property :name
        end

        collection :songs, embedded: true, render_empty: false do
          property :title
        end
      end
    end

    it { decorator_class.new(Album.new(Artist.new("Bare, Jr."), [Song.new("Tobacco Spit")])).to_hash.must_equal({"_embedded"=>{"artist"=>{"name"=>"Bare, Jr."}, "songs"=>[{"title"=>"Tobacco Spit"}]}}) }
    it { decorator_class.new(Album.new).to_hash.must_equal({}) }
  end

  describe "as: alias" do
    let(:decorator_class) do
      Class.new(Roar::Decorator) do
        include Roar::JSON
        include Roar::JSON::HAL

        property :artist, as: :my_artist, class: Artist, embedded: true do
          property :name
        end

        collection :songs, as: :my_songs, class: Song, embedded: true do
          property :title
        end
      end
    end

    it { decorator_class.new(Album.new(Artist.new("Bare, Jr."), [Song.new("Tobacco Spit")])).to_hash.must_equal({"_embedded"=>{"my_artist"=>{"name"=>"Bare, Jr."}, "my_songs"=>[{"title"=>"Tobacco Spit"}]}}) }
    it { decorator_class.new(Album.new).from_hash({"_embedded"=>{"my_artist"=>{"name"=>"Bare, Jr."}, "my_songs"=>[{"title"=>"Tobacco Spit"}]}}).inspect.must_equal "#<struct JsonHalTest::Album artist=#<struct JsonHalTest::Artist name=\"Bare, Jr.\">, songs=[#<struct JsonHalTest::Song title=\"Tobacco Spit\">]>" }
  end
end

class HalCurieTest < MiniTest::Spec
  let(:decorator_class) do
    Class.new(Roar::Decorator) do
      include Roar::JSON
      include Roar::JSON::HAL

      link "doc:self" do
        "/"
      end

      links "doc:link_collection" do
        [{:name => "link_collection", :href => "/"}]
      end

      curies do
        [{:name => :doc,
          :href => "//docs/{rel}",
          :templated => true}]
      end
    end
  end

  subject { decorator_class.new(Object.new) }

  it { subject.to_hash.must_equal({"_links"=>{"doc:self"=>{"href"=>"/"}, "doc:link_collection"=>[{"name"=>"link_collection", "href"=>"/"}], "curies"=>[{"name"=>:doc, "href"=>"//docs/{rel}", "templated"=>true}]}}) }
end
