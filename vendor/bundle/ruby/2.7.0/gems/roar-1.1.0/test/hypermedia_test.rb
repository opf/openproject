require 'test_helper'
require 'roar/decorator'

class HypermediaTest < MiniTest::Spec
  describe "inheritance" do
    class BaseRepresenter < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia

      link(:base) { "http://base" }
    end

    class Bar < BaseRepresenter
      link(:bar) { "http://bar" }
    end

    class Foo < Bar
      link(:foo) { "http://foo" }
    end

    it "inherits parent links" do
      Foo.new(Object.new).to_json.must_equal "{\"links\":[{\"rel\":\"base\",\"href\":\"http://base\"},{\"rel\":\"bar\",\"href\":\"http://bar\"},{\"rel\":\"foo\",\"href\":\"http://foo\"}]}"
    end

    it "inherits links from all mixed-in representers" do
      Bar.new(Object.new).to_json.must_equal "{\"links\":[{\"rel\":\"base\",\"href\":\"http://base\"},{\"rel\":\"bar\",\"href\":\"http://bar\"}]}"
    end
  end

  describe "#links_array" do
    subject { decorator_class.new(Object.new) }

    decorator_for do
      link(:self) { "//self" }
    end

    describe "#to_json" do
      it "renders" do
        subject.to_json.must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self\"}]}"
      end
    end

    describe "#from_json" do
      it "parses" do
        subject.from_json "{\"links\":[{\"rel\":\"self\",\"href\":\"//self\"}]}"
        subject.links.must_equal("self" => link("rel" => "self", "href" => "//self"))
      end
    end


    describe "#link" do

      describe "with any options" do
        decorator_for do
          link(:rel => :self, :title => "Hey, @myabc") { "//self" }
        end

        it "renders options" do
          subject.to_json.must_equal "{\"links\":[{\"rel\":\"self\",\"title\":\"Hey, @myabc\",\"href\":\"//self\"}]}"
        end
      end

      describe "with string rel" do
        decorator_for do
          link("ns:self") { "//self" }
        end

        it "renders rel" do
          # raise subject.inspect
          subject.to_json.must_equal "{\"links\":[{\"rel\":\"ns:self\",\"href\":\"//self\"}]}"
        end
      end

      describe "passing options to serialize" do
        decorator_for do
          link(:self) { |opts| "//self/#{opts[:id]}" }
        end

        it "receives options when rendering" do
          subject.to_json(user_options: { id: 1 }).must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self/1\"}]}"
        end

        describe "in a composition" do
          decorator_for do
            property :entity, :extend => self
            link(:self) { |opts| "//self/#{opts[:id]}" }
          end

          it "propagates options" do
            decorator_class.new(Song.new(:entity => Song.new)).to_json(user_options: { id: 1 }).must_equal "{\"entity\":{\"links\":[{\"rel\":\"self\",\"href\":\"//self/1\"}]},\"links\":[{\"rel\":\"self\",\"href\":\"//self/1\"}]}"
          end
        end
      end

      describe "returning option hash from block" do
        decorator_for do
          link(:self) do {:href => "//self", :type => "image/jpg"} end
          link(:other) do |params|
            hash = { :href => "//other" }
            hash.merge!(:type => 'image/jpg') if params[:type]
            hash
          end
        end

        it "is rendered as link attributes" do
          subject.to_json.must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self\",\"type\":\"image/jpg\"},{\"rel\":\"other\",\"href\":\"//other\"}]}"
        end

        it "is rendered according to context" do
          subject.to_json(user_options: { type: true }).must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self\",\"type\":\"image/jpg\"},{\"rel\":\"other\",\"href\":\"//other\",\"type\":\"image/jpg\"}]}"
          subject.to_json.must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self\",\"type\":\"image/jpg\"},{\"rel\":\"other\",\"href\":\"//other\"}]}"
        end
      end

      describe "not calling #link" do
        decorator_for {}

        it "still allows rendering" do
          subject.to_json.must_equal "{}"
        end
      end
    end
  end
end
