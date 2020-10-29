require 'test_helper'
require 'roar/decorator'

class DecoratorTest < MiniTest::Spec
  class SongRepresentation < Roar::Decorator
    include Roar::JSON

    property :name
  end

  describe "Decorator" do
    let (:song) { OpenStruct.new(:name => "Not The Same") }

    it "exposes ::prepare" do
      SongRepresentation.prepare(song).to_hash.must_equal({"name"=>"Not The Same"})
    end
  end

  describe "Hypermedia modules" do
    representer_for do
      link(:self) { "http://self" } # TODO: test with Collection::JSON, too.
    end

    let (:model) { Object.new }
    let (:model_with_links) { model.singleton_class.instance_eval { attr_accessor :links }; model }

    describe "JSON" do
      let (:decorator_class) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include Roar::JSON
          include Roar::Hypermedia

          include rpr_mod
        end }
      let (:decorator) { decorator_class.new(model) }

      it "xxxrendering links works" do
        pp decorator.send(:representable_attrs)
        decorator.to_hash.must_equal({"links"=>[{"rel"=>"self", "href"=>"http://self"}]})
      end

      it "sets links on decorator" do
        decorator.from_hash("links"=>[{:rel=>:self, :href=>"http://next"}])
        decorator.links.must_equal("self"=>link(:rel=>:self, :href=>"http://next"))
      end

      it "does not set links on represented" do
        decorator_class.new(model_with_links).from_hash("links"=>[{:rel=>:self, :href=>"http://self"}])
        model_with_links.links.must_be_nil
      end

      class ConsumingDecorator < Roar::Decorator
        include Roar::JSON
        include Roar::Hypermedia
        link(:self) { "http://self" }

        include HypermediaConsumer
      end

      # TODO: test include ModuleWithLinks

      describe "Decorator::HypermediaClient" do
        it "propagates links to represented" do
          decorator = ConsumingDecorator.new(model_with_links)


          decorator.from_hash("links"=>[{:rel=>:self, :href=>"http://percolator"}])

          # links are always set on decorator instance.
          decorator.links["self"].must_equal(link(:rel=>:self, :href=>"http://percolator"))

          # and propagated to represented with HypermediaConsumer.
          model_with_links.links["self"].must_equal(link(:rel=>:self, :href=>"http://percolator"))
        end
      end
    end

    describe "XML" do
      representer_for([Roar::XML, Roar::Hypermedia]) do
        link(:self) { "http://self" } # TODO: test with HAL, too.
        #self.representation_wrap = :song   # FIXME: why isn't this working?
      end
      let (:decorator_class) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include Roar::XML
          include Roar::Hypermedia
          include rpr_mod
          self.representation_wrap = :song
        end
      }
      let (:decorator) { decorator_class.new(model) }

      it "rendering links works" do
        decorator.to_xml.must_equal_xml "<song><link rel=\"self\" href=\"http://self\"/></song>"
      end

      it "sets links on decorator" do
        decorator.from_xml(%{<song><link rel="self" href="http://next"/></song>})
        decorator.links.must_equal("self"=>link(:rel=>"self", :href=>"http://next"))
      end
    end


    describe "JSON::HAL" do
      representer_for([Roar::JSON::HAL]) do
        # feature Roar::JSON::HAL
        link(:self) { "http://self" }
      end
      let (:decorator_class) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include Roar::JSON::HAL

          include rpr_mod
        end
      }
      let (:decorator) { decorator_class.new(model) }

      it "rendering links works" do
        decorator.to_hash.must_equal({"_links"=>{"self"=>{"href"=>"http://self"}}})
      end

      it "sets links on decorator" do
        decorator.from_hash({"_links"=>{"self"=>{"href"=>"http://next"}}})
        decorator.links.must_equal("self"=>link("rel"=>"self", "href"=>"http://next"))
      end

      describe "Decorator::HypermediaClient" do
        let (:decorator_class) { rpr_mod = rpr
          Class.new(Roar::Decorator) do
            include Roar::JSON::HAL
            include rpr_mod
            include Roar::Decorator::HypermediaConsumer
          end }

        it "propagates links to represented" do
          decorator_class.new(model_with_links).from_hash("_links"=>{"self"=>{:href=>"http://self"}})
          model_with_links.links["self"].must_equal(link(:rel=>"self", :href=>"http://self"))
        end
      end
    end
  end
end
