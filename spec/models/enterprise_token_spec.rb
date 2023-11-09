require 'spec_helper'

RSpec.describe EnterpriseToken do
  let(:object) { OpenProject::Token.new domain: Setting.host_name }

  subject { described_class.new(encoded_token: 'foo') }

  before do
    RequestStore.delete :current_ee_token
    allow(OpenProject::Configuration).to receive(:ee_manager_visible?).and_return(true)
  end

  describe '.active?' do
    before do
      allow(described_class).to receive(:current).and_return(subject)
      allow(described_class.current).to receive(:token_object).and_return(object)
      subject.save!(validate: false)
    end

    context 'with a non expired token' do
      before do
        allow(object).to receive(:expired?).and_return(false)
      end

      it 'returns true' do
        expect(described_class.active?).to be(true)
      end
    end

    context 'with an expired token' do
      before do
        allow(object).to receive(:expired?).and_return(true)
      end

      it 'returns false' do
        expect(described_class.active?).to be(false)
      end
    end
  end

  describe 'existing token' do
    before do
      allow_any_instance_of(EnterpriseToken).to receive(:token_object).and_return(object)
      subject.save!(validate: false)
    end

    context 'when inner token is active' do
      it 'has an active token' do
        expect(object).to receive(:expired?).and_return(false)
        expect(described_class.count).to eq(1)
        expect(described_class.current).to eq(subject)
        expect(described_class.current.encoded_token).to eq('foo')
        expect(described_class.show_banners?).to be(false)

        # Deleting it updates the current token
        described_class.current.destroy!

        expect(described_class.count).to eq(0)
        expect(described_class.current).to be_nil
      end

      it 'delegates to the token object' do
        allow(object).to receive_messages(
          subscriber: 'foo',
          mail: 'bar',
          starts_at: Date.today,
          issued_at: Date.today,
          expires_at: 'never',
          restrictions: { foo: :bar }
        )

        expect(subject.subscriber).to eq('foo')
        expect(subject.mail).to eq('bar')
        expect(subject.starts_at).to eq(Date.today)
        expect(subject.issued_at).to eq(Date.today)
        expect(subject.expires_at).to eq('never')
        expect(subject.restrictions).to eq(foo: :bar)
      end

      describe '#allows_to?' do
        let(:service_double) { Authorization::EnterpriseService.new(subject) }

        before do
          expect(Authorization::EnterpriseService)
            .to receive(:new).twice.with(subject).and_return(service_double)
        end

        it 'forwards to EnterpriseTokenService for checks' do
          expect(service_double)
            .to receive(:call)
            .with(:forbidden_action)
            .and_return double('ServiceResult', result: false)
          expect(service_double)
            .to receive(:call)
            .with(:allowed_action)
            .and_return double('ServiceResult', result: true)

          expect(described_class.allows_to?(:forbidden_action)).to be false
          expect(described_class.allows_to?(:allowed_action)).to be true
        end
      end
    end

    context 'when inner token has feature' do
      let(:object) do
        OpenProject::Token.new domain: Setting.host_name,
                               features: %i[some_feature]
      end

      it 'provides that feature' do
        expect(described_class.allows_to?(:some_feature)).to be true
        expect(described_class.allows_to?('some_feature')).to be true
        expect(described_class.allows_to?(:other_feature)).to be false
      end

      it 'extends show_banners' do
        expect(described_class.show_banners?).to be false
        expect(described_class.show_banners?(:other_feature)).to be true
        expect(described_class.show_banners?('some_feature')).to be false
        expect(described_class.show_banners?(:some_feature)).to be false
      end
    end

    context 'when inner token is expired' do
      before do
        expect(object).to receive(:expired?).and_return(true)
      end

      it 'has an expired token' do
        expect(described_class.current).to eq(subject)
        expect(described_class.show_banners?).to be(true)
      end
    end

    context 'updating it with an invalid token' do
      it 'will fail validations' do
        subject.encoded_token = "bar"
        expect(subject.save).to be_falsey
      end
    end
  end

  describe 'no token' do
    it do
      expect(described_class.current).to be_nil
      expect(described_class.show_banners?).to be(true)
    end
  end

  describe 'invalid token' do
    it 'appears as if no token is shown' do
      expect(described_class.current).to be_nil
      expect(described_class.show_banners?).to be(true)
    end
  end

  describe "Configuration file has `ee_manager_visible` set to false" do
    it 'does not show banners promoting EE' do
      expect(OpenProject::Configuration).to receive(:ee_manager_visible?).and_return(false)
      expect(described_class.show_banners?).to be_falsey
    end
  end
end
