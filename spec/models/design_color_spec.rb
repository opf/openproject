require 'spec_helper'

RSpec.describe DesignColor, type: :model do
  let(:default_primary) { ::OpenProject::Design.variables['primary-color'] }
  let(:primary_color) { FactoryGirl.create :"design_color_primary-color" }

  describe "#defaults" do
    it "returns a hash of default color variables with hex color codes" do
      expect(described_class.defaults).to be_a(Hash)
      expect(described_class.defaults["primary-color"]).to eq(default_primary)
    end
  end

  describe "#setables" do
    it "returns an Array of instances" do
      expect(described_class.setables).to be_a(Array)
      expect(described_class.setables.first).to be_a(described_class)
    end

    it 'not overwritten defaults do not have a color set' do
      expect(described_class.setables.first.hexcode).to be_nil
    end

    it "instances overwrite defaults" do
      primary_color
      expect(described_class.setables.first.hexcode).to eq("#3493B3")
      expect(described_class.setables.second.hexcode).to be_nil
    end
  end

  describe "#get_hexcode" do
    it "returns hexcode if present" do
      primary_color
      expect(primary_color.get_hexcode).to eq("#3493B3")
    end

    it "returns default hexcode if hexcode not present" do
      expect(described_class.new(variable: "primary-color").get_hexcode)
        .to eq(default_primary)
    end
  end

  describe "validations" do
    context "a color_variable already exists" do
      let(:design_color) do
        DesignColor.new variable: "foo", hexcode: "#AB1234"
      end

      before do
        design_color.save
      end

      it 'fails validation for another design_color with same name' do
        second_color_variable = DesignColor.new variable: "foo", hexcode: "#888888"
        expect(second_color_variable.valid?).to be_falsey
      end
    end

    context "the hexcode's validation" do
      it "fails validations" do
        expect(DesignColor.new(variable: "foo", hexcode: "1").valid?).to be_falsey
        expect(DesignColor.new(variable: "foo", hexcode: "#1").valid?).to be_falsey
        expect(DesignColor.new(variable: "foo", hexcode: "#1111111").valid?).to be_falsey
        expect(DesignColor.new(variable: "foo", hexcode: "#HHHHHH").valid?).to be_falsey
      end

      it "passes validations" do
        expect(DesignColor.new(variable: "foo", hexcode: "111111").valid?).to be_truthy
        expect(DesignColor.new(variable: "foo", hexcode: "#111111").valid?).to be_truthy
        expect(DesignColor.new(variable: "foo", hexcode: "#ABC123").valid?).to be_truthy
        expect(DesignColor.new(variable: "foo", hexcode: "#111").valid?).to be_truthy
        expect(DesignColor.new(variable: "foo", hexcode: "111").valid?).to be_truthy
      end
    end
  end

  describe "#create" do
    context "no CustomStyle.current exists yet" do
      subject { DesignColor.new variable: "foo", hexcode: "#111111" }
      it 'should create a CustomStyle.current' do
        expect(CustomStyle.current).to be_nil
        subject.save
        expect(CustomStyle.current).to be_present
      end
    end
  end
end
