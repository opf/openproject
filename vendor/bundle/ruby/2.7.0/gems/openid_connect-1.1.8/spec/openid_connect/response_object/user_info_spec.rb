require 'spec_helper'

describe OpenIDConnect::ResponseObject::UserInfo do
  let(:klass) { OpenIDConnect::ResponseObject::UserInfo }
  let(:instance) { klass.new attributes }
  subject { instance }

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [] }
    its(:optional_attributes) do
      should == [
        :sub,
        :name,
        :given_name,
        :family_name,
        :middle_name,
        :nickname,
        :preferred_username,
        :profile,
        :picture,
        :website,
        :email,
        :email_verified,
        :gender,
        :birthdate,
        :zoneinfo,
        :locale,
        :phone_number,
        :phone_number_verified,
        :address,
        :updated_at
      ]
    end
  end

  describe 'validations' do
    subject do
      _instance_ = instance
      _instance_.valid?
      _instance_
    end

    context 'when all attributes are blank' do
      let :attributes do
        {}
      end
      its(:valid?) { should == false }
      its(:errors) { should include :base }
    end

    context 'when email is invalid' do
      let :attributes do
        {email: 'nov@localhost'}
      end
      its(:valid?) { should == false }
      its(:errors) { should include :email }
    end

    [:email_verified, :zoneinfo].each do |one_of_list|
      context "when #{one_of_list} is invalid" do
        let :attributes do
          {one_of_list => 'Out of List'}
        end
        its(:valid?) { should == false }
        its(:errors) { should include one_of_list }
      end
    end

    context "when locale is invalid" do
      it :TODO
    end

    [:profile, :picture, :website].each do |url|
      context "when #{url} is invalid" do
        let :attributes do
          {url => 'Invalid'}
        end
        its(:valid?) { should == false }
        its(:errors) { should include url }
      end
    end

    context 'when address is blank' do
      let :attributes do
        {address: {}}
      end
      its(:valid?) { should == false }
      its(:errors) { should include :address }
    end
  end

  describe '#address=' do
    context 'when Hash is given' do
      let :attributes do
        {address: {}}
      end
      its(:address) { should be_a OpenIDConnect::ResponseObject::UserInfo::Address }
    end

    context 'when Address is given' do
      let :attributes do
        {address: OpenIDConnect::ResponseObject::UserInfo::Address.new}
      end
      its(:address) { should be_a OpenIDConnect::ResponseObject::UserInfo::Address }
    end
  end

  describe '#to_json' do
    let :attributes do
      {
        sub: 'nov.matake#12345',
        address: {
          formatted: 'Tokyo, Japan'
        }
      }
    end
    its(:to_json) { should include '"sub":"nov.matake#12345"'}
    its(:to_json) { should include '"address":{"formatted":"Tokyo, Japan"}'}
  end
end