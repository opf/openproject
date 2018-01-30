require 'spec_helper'

describe LdapGroups::SynchronizedGroup, type: :model do
  subject { FactoryGirl.build :ldap_synchronized_group }

  describe '#escaped_entry' do
    it 'escapes the entry for ldap' do
      subject.entry = '<script>alert("1");</script>'
      expect(subject.escaped_entry).to eq("\\<script\\>alert(\\\"1\\\")\\;\\</script\\>")
    end
  end

  describe '#dn' do
    before do
      allow(Setting).to receive(:plugin_openproject_ldap_groups)
        .and_return(group_base: 'ou=example,ou=org', group_key: 'uid')
    end

    it 'uses the plugin settings' do
      subject.entry = 'myattr'
      expect(subject.dn).to eq 'uid=myattr,ou=example,ou=org'
    end

    it 'escapes the value in the dn' do
      subject.entry = '<script>alert("1");</script>'
      expect(subject.dn).to eq "uid=\\<script\\>alert(\\\"1\\\")\\;\\</script\\>,ou=example,ou=org"
    end
  end

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
        expect(subject.errors[:entry]).to include "can't be blank."
        expect(subject.errors[:auth_source]).to include "can't be blank."
        expect(subject.errors[:group]).to include "can't be blank."
      end
    end
  end
end