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

module WorkPackages
  module Shared
    module FindOrCreateLabels
      def find_or_create_labels(work_package)
        return ServiceResult.success(result: work_package) if work_package.label_name_replacements.blank?

        call = find_or_create_label_ids(work_package.label_name_replacements)

        if call.success?
          work_package.replace_label_names_with_ids(call.result)
          ServiceResult.success(result: work_package)
        else
          add_label_error(work_package, call.errors)
          ServiceResult.failure(result: work_package, errors: work_package.errors)
        end
      end

      private

      def add_label_error(work_package, label_errors)
        detail = label_errors.details[:name].first || { error: :invalid }
        work_package.errors.add(:labels, detail[:error], **detail.except(:error))
      end

      def find_or_create_label_ids(names)
        service = Labels::FindOrCreateService.new(user:)
        ids = []

        # A stable order keeps concurrent saves with overlapping new names from
        # deadlocking on the unique name index.
        names.sort_by(&:downcase).each do |name|
          call = service.call(name:)
          return call if call.failure?

          ids << call.result.id
        end

        ServiceResult.success(result: ids)
      end
    end
  end
end
