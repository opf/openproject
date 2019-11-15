require 'spec_helper'

describe IFCModels::UpdateService do
  let(:user) { FactoryBot.build_stubbed :admin }
  let(:ifc_attachment_version_1) { FileHelpers.mock_uploaded_file(name: "model_1.ifc", content_type: 'application/binary', binary: true) }
  let(:ifc_attachment_version_2) { FileHelpers.mock_uploaded_file(name: "model_2.ifc", content_type: 'application/binary', binary: true) }

  let(:ifc_model) do
    ::IFCModels::IFCModel.create(ifc_attachment: ifc_attachment_version_1,
                                 title: "Architecture",
                                 is_default: false,
                                 uploader: user)
  end

  let(:instance) { described_class.new(user: user, model: ifc_model) }

  subject { instance.call(params) }

  describe '#call' do
    let (:contract_result) {  }

    context 'when user is allowed' do
      let(:params) do
        {
          is_default: true,
          ifc_attachment: ifc_attachment_version_2
        }.with_indifferent_access
      end

      it 'returns a model from the params and queues conversion' do
        expect(subject).to be_success

        model = subject.result
        expect(model.ifc_attachment.filename).to eq('model_2.ifc')
        expect(model.is_default).to be_truthy
        expect(::IFCModels::IFCConversionJob)
          .to have_been_enqueued
          .with(model)
          .on_queue('ifc_conversion')
      end

      context 'only updating title and is_default' do
        let(:params) do
          {
            is_default: true,
            title: "New title"
          }
        end

        it 'updates the title and is_default even without updating ifc_attachments' do
          expect(subject).to be_success
          model = subject.result

          expect(model.title).to eq('New title')
          expect(::IFCModels::IFCConversionJob)
            .to_not have_been_enqueued
                    .with(model)
        end
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
        model = ifc_model.reload

        expect(model.title).to_not eq('foo')
        expect(::IFCModels::IFCConversionJob)
          .to_not have_been_enqueued
                  .with(model)
      end
    end
  end
end