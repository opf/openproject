require 'spec_helper'

describe Versions::Scopes::OrderBySemverName, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let!(:version1) do
    FactoryBot.create(:version, name: "aaaaa 1.", project: project)
  end
  let!(:version2) do
    FactoryBot.create(:version, name: "aaaaa", project: project)
  end
  let!(:version3) do
    FactoryBot.create(:version, name: "1.10. aaa", project: project)
  end
  let!(:version4) do
    FactoryBot.create(:version, name: "1.1. zzz", project: project, start_date: Date.today, effective_date: Date.today + 1.day)
  end
  let!(:version5) do
    FactoryBot.create(:version, name: "1.2. mmm", project: project, start_date: Date.today)
  end
  let!(:version6) do
    FactoryBot.create(:version, name: "1. xxxx", project: project, start_date: Date.today + 5.days)
  end
  let!(:version7) do
    FactoryBot.create(:version, name: "1.1. aaa", project: project)
  end

  it 'returns the versions in semver order' do
    expect(described_class.fetch.to_a)
      .to eql [version6, version7, version4, version5, version3, version2, version1]
  end

  it 'is also callable on the version class' do
    expect(Version.order_by_semver_name.to_a)
      .to eql [version6, version7, version4, version5, version3, version2, version1]
  end
end
