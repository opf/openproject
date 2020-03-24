require 'spec_helper'

describe Versions::Scopes::OrderBySemverName, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let!(:version1) { FactoryBot.create(:version, name: "aaaaa 1.", project: project) }
  let!(:version2) { FactoryBot.create(:version, name: "aaaaa", project: project) }
  let!(:version3) { FactoryBot.create(:version, name: "1.10. aaa", project: project) }
  let!(:version4) { FactoryBot.create(:version, name: "1.1. zzz", project: project) }
  let!(:version5) { FactoryBot.create(:version, name: "1.2. mmm", project: project) }
  let!(:version6) { FactoryBot.create(:version, name: "1. xxxx", project: project) }

  it 'returns the versions in semver order' do
    expect(described_class.fetch.to_a)
      .to eql [version6, version4, version5, version3, version2, version1]
  end
end
