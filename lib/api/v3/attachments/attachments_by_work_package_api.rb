#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'api/v3/attachments/attachment_collection_representer'

module API
  module V3
    module Attachments
      class AttachmentsByWorkPackageAPI < ::API::OpenProjectAPI
        resources :attachments do
          helpers API::V3::Attachments::AttachmentsByContainerAPI::Helpers

          helpers do
            def container
              @work_package
            end

            def get_attachment_self_path
              api_v3_paths.attachments_by_work_package(container.id)
            end
          end

          get &API::V3::Attachments::AttachmentsByContainerAPI.read

          # while attachments are #addable? when the user has the :add_work_packages permission or
          # the :edit_work_packages permission, we cannot differentiate here between adding to a newly
          # created work package (for which :add_work_package would be required) and adding to an older
          # work package (for which :edit_work_packages would be required). We thus only allow
          # :edit_work_packages in this endpoint and require clients to upload uncontainered work packages
          # first and attach them on wp creation.
          post &API::V3::Attachments::AttachmentsByContainerAPI.create([:edit_work_packages])
        end
      end
    end
  end
end
