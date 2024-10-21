require "spec_helper"

RSpec.describe Versions::Scopes::OrderBySemverName do
  let(:project) { create(:project) }
  let(:names) do
    [
      "1. xxxx",
      "1.1. aaa",
      "1.1. zzz",
      "1.2. mmm",
      "1.10. aaa",
      "9",
      "10.2",
      "10.10.2",
      "10.10.10",
      "aaaaa",
      "aaaaa 1."
    ]
  end
  let!(:versions) { names.map { |name| create(:version, name:, project:) } }

  subject { Version.order_by_semver_name.order(id: :desc).to_a }

  it "returns the versions in semver order" do
    expect(subject)
      .to eql versions
  end
end
