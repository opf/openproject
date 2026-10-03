require "spec_helper"

RSpec.describe TypeScheme do
  let(:epic)  { create(:type, name: "Epic") }
  let(:story) { create(:type, name: "Story") }

  def build_scheme(items)
    described_class.new(name: "Dev").tap do |scheme|
      items.each_with_index do |(type, default), i|
        scheme.items.build(type:, position: i + 1, is_default: default)
      end
    end
  end

  it "requires a name" do
    expect(described_class.new).not_to be_valid
  end

  it "rejects duplicate types" do
    expect(build_scheme([[epic, true], [epic, false]])).not_to be_valid
  end

  it "requires exactly one default item when active" do
    expect(build_scheme([[epic, false], [story, false]])).not_to be_valid
    expect(build_scheme([[epic, true], [story, true]])).not_to be_valid
    expect(build_scheme([[epic, false], [story, true]])).to be_valid
  end

  it "exposes ordered types and default type" do
    scheme = build_scheme([[epic, false], [story, true]]).tap(&:save!)
    expect(scheme.types).to eq([epic, story])
    expect(scheme.default_type).to eq(story)
  end

  it "allows only one default scheme" do
    create(:type_scheme, is_default: true)
    expect(build(:type_scheme, is_default: true)).not_to be_valid
  end
end
