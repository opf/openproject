# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module SquashTMIntegration
  module WorkPackageLinks
    class UpdateService < ::BaseServices::Update
      include Journalizable

      protected

      def after_perform(service_call)
        journalize_replacement(service_call.result)

        super
      end

      private

      def journalize_replacement(link)
        return unless link.saved_change_to_squashtm_requirement_id?

        journalize(link.work_package, Journal::CausedBySquashTMRequirementUnlinked,
                   link.squashtm_requirement_id_before_last_save, link.squashtm_requirement_name_before_last_save,
                   link.squashtm_requirement_reference_before_last_save)
        journalize_linked(link)
      end
    end
  end
end
