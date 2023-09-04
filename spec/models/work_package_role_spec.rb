require 'spec_helper'

RSpec.describe WorkPackageRole do
  subject do
    described_class.create(name: 'work_package_role',
                           permissions: %w[permissions])
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of :name }
    it { is_expected.to validate_length_of(:name).is_at_most(256) }
  end
end
