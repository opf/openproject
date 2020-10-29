require 'test_helper'
require 'roar/decorator'

class XMLRepresenterFunctionalTest < MiniTest::Spec
  class OrderRepresenter < Roar::Decorator
    include Roar::XML

    property :id
    self.representation_wrap = :order
  end

  Order = Struct.new(:id, :items)

  describe "#to_xml" do
    let (:order) { OrderRepresenter.new(Order.new(1)) }

    # empty model
    it { OrderRepresenter.new(Order.new).to_xml.must_equal_xml "<order/>" }

    # populated model
    it { order.to_xml.must_equal_xml "<order><id>1</id></order>" }

    # with wrap
    it { order.to_xml(wrap: :rap).must_equal_xml "<rap><id>1</id></rap>" }

    # aliased to #serialize
    it { order.to_xml.must_equal order.serialize }

    # accepts options
    it { order.to_xml(exclude: [:id]).must_equal_xml "<order/>" }
  end

  describe "#from_xml" do
    let (:order) { OrderRepresenter.new(Order.new) }

    # parses
    it { order.from_xml("<order><id>1</id></order>").id.must_equal "1" }

    # aliased to #deserialize
    it { order.deserialize("<order><id>1</id></order>").id.must_equal "1" }

    # accepts options
    it { order.from_xml("<order><id>1</id></order>", exclude: [:id]).id.must_be_nil }
  end
end

class XmlHyperlinkRepresenterTest < MiniTest::Spec
  describe "API" do
    before do
      @link = Roar::Hypermedia::Hyperlink.new.extend(Roar::XML::HyperlinkRepresenter).from_xml(%{<link rel="self" href="http://roar.apotomo.de" media="web"/>})
    end

    it "responds to #rel" do
      assert_equal "self", @link.rel
    end

    it "responds to #href" do
      assert_equal "http://roar.apotomo.de", @link.href
    end

    it "responds to #media" do
      assert_equal "web", @link.media
    end

    it "responds to #to_xml" do
      assert_xml_equal %{<link rel=\"self\" href=\"http://roar.apotomo.de\" media="web"/>}, @link.to_xml
    end
  end
end
