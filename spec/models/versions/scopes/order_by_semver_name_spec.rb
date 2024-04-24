require "spec_helper"

RSpec.describe Versions::Scopes::OrderBySemverName do
  let(:project) { create(:project) }
  let!(:version1) do
    create(:version, name: "aaaaa 1.", project:)
  end
  let!(:version2) do
    create(:version, name: "aaaaa", project:)
  end
  let!(:version3) do
    create(:version, name: "1.10. aaa", project:)
  end
  let!(:version4) do
    create(:version, name: "1.1. zzz", project:, start_date: Date.today, effective_date: Date.today + 1.day)
  end
  let!(:version5) do
    create(:version, name: "1.2. mmm", project:, start_date: Date.today)
  end
  let!(:version6) do
    create(:version, name: "1. xxxx", project:, start_date: Date.today + 5.days)
  end
  let!(:version7) do
    create(:version, name: "1.1. aaa", project:)
  end

  subject { Version.order_by_semver_name }

  it "returns the versions in semver order" do
    expect(subject.to_a)
      .to eql [version6, version7, version4, version5, version3, version2, version1]
  end
end
