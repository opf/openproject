require 'test_helper'

class ConfigTest < MiniTest::Spec
  subject { Representable::Config.new(Representable::Definition) }
  PunkRock = Class.new
  Definition = Representable::Definition

  describe "wrapping" do
    it "returns false per default" do
      assert_nil subject.wrap_for("Punk", nil)
    end

    # it "infers a printable class name if set to true" do
    #   subject.wrap = true
    #   assert_equal "punk_rock", subject.wrap_for(PunkRock, nil)
    # end

    # it "can be set explicitely" do
    #   subject.wrap = "Descendents"
    #   assert_equal "Descendents", subject.wrap_for(PunkRock, nil)
    # end
  end

  describe "#[]" do
    # does return nil for non-existent
    it { subject[:hello].must_be_nil }
  end

  # describe "#[]" do
  #   before { subject.add(:title, {:me => true}) }

  #   it { subject[:unknown].must_be_nil }
  #   it { subject.get(:title)[:me].must_equal  true }
  #   it { subject["title"][:me].must_equal true }
  # end

  # []=
  # []=(... inherit: true)
  # forwarded to Config#definitions
  # that goes to ConfigDefinitionsTest
  describe "#add" do
    describe "returns" do
      it do
        # #add returns Definition.`
        subject = Representable::Config.new(Representable::Definition).add(:title, {:me => true})

        subject.must_be_kind_of Representable::Definition
        subject[:me].must_equal true
      end
    end

    before { subject.add(:title, {:me => true}) }

    # must be kind of Definition
    it { subject.size.must_equal 1 }
    it { subject.get(:title).name.must_equal "title" }
    it { subject.get(:title)[:me].must_equal true }

    # this is actually tested in context in inherit_test.
    it "overrides former definition" do
      subject.add(:title, {:peer => Module})
      subject.get(:title)[:me].must_be_nil
      subject.get(:title)[:peer].must_equal Module
    end

    describe "inherit: true" do
      before {
        subject.add(:title, {:me => true})
        subject.add(:title, {:peer => Module, :inherit => true})
      }

      it { subject.get(:title)[:me].must_equal true }
      it { subject.get(:title)[:peer].must_equal Module }
    end
  end


  describe "#remove" do
    subject { Representable::Config.new(Representable::Definition) }

    it do
      subject.add(:title, {:me => true})
      subject.add(:genre, {})
      subject.get(:genre).must_be_kind_of Representable::Definition

      subject.remove(:genre)
      subject.get(:genre).must_be_nil
    end
  end


  describe "#each" do
    before { subject.add(:title, {:me => true}) }

    it "what" do
      definitions = []
      subject.each { |dfn| definitions << dfn }
      definitions.size.must_equal 1
      definitions[0][:me].must_equal true
    end
  end

  describe "#options" do
    it { subject.options.must_equal({}) }
    it do
      subject.options[:namespacing] = true
      subject.options[:namespacing].must_equal true
    end
  end

  describe "#get" do
    subject       { Representable::Config.new(Representable::Definition) }

    it do
      title  = subject.add(:title, {})
      length = subject.add(:length, {})

      subject.get(:title).must_equal title
      subject.get(:length).must_equal length
    end
  end
end