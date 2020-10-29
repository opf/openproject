require 'spec_helper'

describe OpenIDConnect::ConnectObject do
  class OpenIDConnect::ConnectObject::SubClass < OpenIDConnect::ConnectObject
    attr_required :required
    attr_optional :optional
    validates :required, inclusion: {in: ['Required', 'required']}, length: 1..10
  end

  subject        { instance }
  let(:klass)    { OpenIDConnect::ConnectObject::SubClass }
  let(:instance) { klass.new attributes }
  let :attributes do
    {required: 'Required', optional: 'Optional'}
  end

  context 'when required attributes are given' do
    context 'when optional attributes are given' do
      its(:required) { should == 'Required' }
      its(:optional) { should == 'Optional' }
    end

    context 'otherwise' do
      let :attributes do
        {required: 'Required'}
      end
      its(:required) { should == 'Required' }
      its(:optional) { should == nil }
    end
  end

  context 'otherwise' do
    context 'when optional attributes are given' do
      let :attributes do
        {optional: 'Optional'}
      end
      it do
        expect { klass.new attributes }.to raise_error AttrRequired::AttrMissing
      end
    end

    context 'otherwise' do
      it do
        expect { klass.new }.to raise_error AttrRequired::AttrMissing
      end
    end
  end

  describe '#as_json' do
    context 'when valid' do
      its(:as_json) do
        should == attributes
      end
    end

    context 'otherwise' do
      let :attributes do
        {required: 'Out of List and Too Long'}
      end

      it 'should raise OpenIDConnect::ValidationFailed with ActiveModel::Errors owner' do
        expect { instance.as_json }.to raise_error(OpenIDConnect::ValidationFailed) { |e|
          e.message.should include 'Required is not included in the list'
          e.message.should include 'Required is too long (maximum is 10 characters)'
          e.object.errors.should be_a ActiveModel::Errors
        }
      end
    end
  end

  describe '#validate!' do
    context 'when valid' do
      subject { instance.validate! }
      it { should == true }
    end

    context 'otherwise' do
      let :attributes do
        {required: 'Out of List and Too Long'}
      end

      it 'should raise OpenIDConnect::ValidationFailed with ActiveModel::Errors owner' do
        expect { instance.validate! }.to raise_error(OpenIDConnect::ValidationFailed) { |e|
          e.message.should include 'Required is not included in the list'
          e.message.should include 'Required is too long (maximum is 10 characters)'
          e.object.errors.should be_a ActiveModel::Errors
        }
      end
    end
  end
end
