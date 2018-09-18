#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
          end

          post do
            raise API::Errors::Unauthorized if Redmine::Acts::Attachable.attachables.none?(&:attachments_addable?)

            ::API::V3::Attachments::AttachmentRepresenter.new(parse_and_create,
                                                              current_user: current_user)
          end

          params do
            requires :id, desc: 'Attachment id'
          end
          route_param :id do
            before do
              @attachment = Attachment.find(params[:id])

              raise ::API::Errors::NotFound.new unless @attachment.visible?(current_user)
            end

            get do
              AttachmentRepresenter.new(@attachment, embed_links: true, current_user: current_user)
            end

            delete do
              raise API::Errors::Unauthorized unless @attachment.deletable?(current_user)

              if @attachment.container
                @attachment.container.attachments.delete(@attachment)
              else
                @attachment.destroy
              end

              status 204
            end

            namespace :content do
              get do
                if @attachment.external_storage?
                  redirect @attachment.external_url.to_s
                else
                  content_type @attachment.content_type
                  header['Content-Disposition'] = "attachment; filename=#{@attachment.filename}"
                  env['api.format'] = :binary
                  @attachment.diskfile.read
                end
              end
            end
          end
        end
      end
    end
  end
end
