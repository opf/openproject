module API
  module V3
    module Attachments
      class AttachmentsAPI < Grape::API

        resources :attachments do

          params do
            requires :id, desc: 'Attachment id'
          end
          namespace ':id' do

            before do
              @attachment = Attachment.find(params[:id])
              model = ::API::V3::Attachments::AttachmentModel.new(@attachment)
              @representer =  ::API::V3::Attachments::AttachmentRepresenter.new(model)
            end

            get do
              authorize(:work_packages, :show, context: @attachment.container.project)
              @representer.to_json
            end

          end

        end

      end
    end
  end
end
