require 'spec_helper'

RSpec.describe DesignColor, type: :model do
  let(:color_red) { FactoryGirl.create :design_color_red }
  let(:color_blue) { FactoryGirl.create :disign_color_blue }

  describe "#defaults" do
    it "returns an array of default vars with hex color codes" do


    end
  end

  describe "#setables" do
    it "returns a list of variable names that can be overwritten" do

    end
  end

  describe "validations" do
    context "a color_variable already exists" do
      let(:design_color) do
        DesignColor.new( variable: "foo", hexcode: "#AB1234" )
      end

      before do
        design_color.save
      end

      it 'fails validation for another design_color with same name' do
        second_color_variable = DesignColor.new(
          variable: "foo",
          hexcode: "#888888" )
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
