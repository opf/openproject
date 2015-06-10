#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/attachments/attachment_representer'

module API
  module V3
    module Attachments
      class AttachmentsAPI < ::API::OpenProjectAPI
        resources :attachments do

          params do
            requires :id, desc: 'Attachment id'
          end
          route_param :id do

            before do
              @attachment = Attachment.find(params[:id])

              # For now we only support work package attachments
              raise ::API::Errors::NotFound.new unless @attachment.container_type == 'WorkPackage'
              authorize(:view_work_packages, context: @attachment.container.project)
            end

            get do
              AttachmentRepresenter.new(@attachment)
            end

            delete do
              authorize(:edit_work_packages, context: @attachment.container.project)

              @attachment.container.attachments.delete(@attachment)
              status 202
            end
          end
        end
      end
    end
  end
end
