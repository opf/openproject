#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/attachments/attachment_representer'

module API
  module V3
    module Attachments
      class AttachmentsAPI < ::API::OpenProjectAPI
        resources :attachments do
          helpers API::V3::Attachments::AttachmentsByContainerAPI::Helpers

          helpers do
            def container
              nil
            end

            def check_attachments_addable
              raise API::Errors::Unauthorized if Redmine::Acts::Attachable.attachables.none?(&:attachments_addable?)
            end
          end

          post do
            check_attachments_addable

            ::API::V3::Attachments::AttachmentRepresenter.new(parse_and_create, current_user: current_user)
          end

          namespace :prepare do
            post do
              require_direct_uploads
              check_attachments_addable

              ::API::V3::Attachments::AttachmentUploadRepresenter.new(parse_and_prepare, current_user: current_user)
            end
          end

          route_param :id, type: Integer, desc: 'Attachment ID' do
            after_validation do
              @attachment = Attachment.find(params[:id])

              raise ::API::Errors::NotFound.new unless @attachment.visible?(current_user)
            end

            get do
              AttachmentRepresenter.new(@attachment, embed_links: true, current_user: current_user)
            end

            delete &::API::V3::Utilities::Endpoints::Delete.new(model: Attachment).mount

            namespace :content, &::API::Helpers::AttachmentRenderer.content_endpoint(&-> {
              @attachment
            })

            namespace :uploaded do
              get do
                attachment = Attachment.pending_direct_uploads.where(id: params[:id]).first!

                raise API::Errors::NotFound unless attachment.file.readable?

                ::Attachments::FinishDirectUploadJob.perform_later attachment.id

                ::API::V3::Attachments::AttachmentRepresenter.new(attachment, current_user: current_user)
              end
            end
          end
        end
      end
    end
  end
end
