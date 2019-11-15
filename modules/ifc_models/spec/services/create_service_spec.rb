require 'spec_helper'

describe IFCModels::CreateService do
  let(:user) { FactoryBot.build_stubbed :admin }
  let(:ifc_attachment) { FileHelpers.mock_uploaded_file name: "model.ifc", content_type: 'application/binary', binary: true }

  let(:instance) { described_class.new(user: user) }
  subject { instance.call(params) }

  describe '#call' do
    let (:contract_result) {  }

    context 'when user is allowed' do
      let(:params) do
        {
          is_default: true,
          ifc_attachment: ifc_attachment
        }
      end

      it 'returns a model from the params and queues conversion' do
        expect(subject).to be_success

        model = subject.result
        expect(model.ifc_attachment).to be_present
        expect(model.is_default).to be_truthy
        expect(::IFCModels::IFCConversionJob)
          .to have_been_enqueued
          .with(model)
      end
    end

    context 'when contract does not validate' do
      before do
        allow(instance)
          .to(receive(:validate_contract))
          .and_return(ServiceResult.new(success: false))
      end

      let(:params) { { title: 'foo' } }

      it 'returns the service result from contract' do
        expect(subject).not_to be_success
      end
    end
  end
end