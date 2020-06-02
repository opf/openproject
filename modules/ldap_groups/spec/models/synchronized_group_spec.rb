require 'spec_helper'

describe LdapGroups::SynchronizedGroup, type: :model do
  subject { FactoryBot.build :ldap_synchronized_group }

  describe 'validations' do
    context 'correct attributes' do
      it 'saves the record' do
        expect(subject.save).to eq true
      end
    end

    context 'missing attributes' do
      subject { described_class.new }
      it 'validates missing attributes' do
        expect(subject.save).to eq false
        expect(subject.errors[:dn]).to include "can't be blank."
        expect(subject.errors[:auth_source]).to include "can't be blank."
        expect(subject.errors[:group]).to include "can't be blank."
      end
    end
  end
end