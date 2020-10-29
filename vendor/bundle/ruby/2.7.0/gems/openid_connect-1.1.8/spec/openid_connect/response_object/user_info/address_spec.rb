require 'spec_helper'

describe OpenIDConnect::ResponseObject::UserInfo::Address do
  let(:klass) { OpenIDConnect::ResponseObject::UserInfo::Address }

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [] }
    its(:optional_attributes) { should == [:formatted, :street_address, :locality, :region, :postal_code, :country] }
  end

  describe 'validations' do
    subject do
      instance = klass.new attributes
      instance.valid?
      instance
    end

    context 'when all attributes are blank' do
      let :attributes do
        {}
      end
      its(:valid?) { should == false }
      its(:errors) { should include :base }
    end
  end
end