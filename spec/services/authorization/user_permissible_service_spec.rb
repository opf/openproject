require 'rails_helper'

RSpec.describe Authorization::UserPermissibleService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  subject { described_class.new(user) }

  describe '#allowed_globally?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_globally?(permission) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context 'when asking for a permission that is defined' do
      let(:permission) { :create_user }

      context 'and the user is an admin' do
        let(:user) { create(:admin) }

        it { is_expected.to be_allowed_globally(permission) }
      end
    end
  end

  describe '#allowed_in_project?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_in_project?(permission, project) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end
  end

  describe '#allowed_in_any_project?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_in_any_project?(permission) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end
  end

  describe '#allowed_in_entity?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_in_entity?(permission, work_package) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end
  end

  describe '#allowed_in_any_entity?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_in_any_entity?(permission, WorkPackage) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end
  end
end
