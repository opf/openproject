require 'spec_helper'

RSpec.describe License, type: :model do
  let(:object) { OpenProject::License.new }
  subject { License.new(encoded_license: 'foo') }

  before do
    License.set_current_license
  end

  describe 'existing license' do
    before do
      allow_any_instance_of(License).to receive(:license_object).and_return(object)
      subject.save!(validate: false)
    end

    context 'when inner license is active' do
      it 'has an active license' do
        expect(object).to receive(:expired?).and_return(false)
        expect(License.count).to eq(1)
        expect(License.current).to eq(subject)
        expect(License.current.encoded_license).to eq('foo')
        expect(License.show_banners).to eq(false)

        # Deleting it updates the current license
        License.current.destroy!

        expect(License.count).to eq(0)
        expect(License.current).to be_nil
      end

      it 'delegates to the license object' do
        allow(object).to receive_messages(
          licensee: 'foo',
          mail: 'bar',
          starts_at: Date.today,
          issued_at: Date.today,
          expires_at: 'never',
          restrictions: { foo: :bar }
        )

        expect(subject.licensee).to eq('foo')
        expect(subject.mail).to eq('bar')
        expect(subject.starts_at).to eq(Date.today)
        expect(subject.issued_at).to eq(Date.today)
        expect(subject.expires_at).to eq('never')
        expect(subject.restrictions).to eq(foo: :bar)
      end

      it 'allows to define custom styles' do
        allow(object).to receive(:expired?).and_return(false)

        expect(subject.allows_to? :define_custom_style).to eq(true)
      end
    end

    context 'when inner license is expired' do
      before do
        expect(object).to receive(:expired?).and_return(true)
      end

      it 'has an expired license' do
        expect(License.current).to eq(subject)
        expect(License.show_banners).to eq(true)
      end

      it 'prohibits to define custom styles' do
        expect(subject.allows_to? :define_custom_style).to eq(false)
      end
    end
  end

  describe 'no license' do
    it do
      expect(License.current).to be_nil
      expect(License.show_banners).to eq(true)
    end
  end

  describe 'invalid license' do
    it 'appears as if no license is shown' do
      expect(License.current).to be_nil
      expect(License.show_banners).to eq(true)
    end
  end
end
