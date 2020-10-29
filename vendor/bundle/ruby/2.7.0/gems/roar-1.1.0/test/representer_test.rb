require 'test_helper'

class RepresenterTest < MiniTest::Spec
  describe "Representer" do
    before do
      @c = Class.new do
        include Roar::Representer
      end
    end

    it "aliases #representable_property to #property" do
      @c.property :title
      assert_equal "title", @c.representable_attrs.first.name
    end

    it "aliases #representable_collection to #collection" do
      @c.collection :songs
      assert_equal "songs", @c.representable_attrs.first.name
    end
  end

  describe "Inheritance" do
    it "properly inherits properties from modules" do
      module PersonRepresentation
        include Roar::JSON
        property :name
      end

      class Person
        include AttributesConstructor
        include Roar::JSON
        include PersonRepresentation
        attr_accessor :name
      end

      assert_equal "{\"name\":\"Paulo\"}", Person.new(:name => "Paulo").to_json
    end
  end
end
