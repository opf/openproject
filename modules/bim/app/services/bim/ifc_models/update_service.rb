#-- copyright
# OpenProject is a project management system.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# +

module Bim
  module IfcModels
    class UpdateService < ::BaseServices::Update
      protected

      def before_perform(params, _service_result)
        @ifc_attachment_updated = params[:ifc_attachment].present?

        super
      end

      def after_perform(service_result)
        if service_result.success?
          # As the attachments association does not have the autosave option, we need to remove the
          # attachments ourselves
          model.attachments.select(&:marked_for_destruction?).each(&:destroy)

          if @ifc_attachment_updated
            model.update(conversion_status: ::Bim::IfcModels::IfcModel.conversion_statuses[:pending],
                         conversion_error_message: nil)

            IfcConversionJob.perform_later(service_result.result)
          end
        end

        service_result
      end
    end
  end
end
