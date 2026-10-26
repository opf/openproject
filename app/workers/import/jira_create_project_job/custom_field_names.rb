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

module Import
  class JiraCreateProjectJob
    module CustomFieldNames
      # The counter `unique_name` appends when a name is taken and cannot be reused (e.g. int vs float type of the field)
      NUMBERING_SUFFIX = /\s*\(\d+\)\z/

      module_function

      # Matches `Example`, `Example (2)`, `Example (DYX)` and `Example (DYX, ABC)
      def candidates(base_name)
        escaped = ActiveRecord::Base.sanitize_sql_like(base_name)
        WorkPackageCustomField
          .where("LOWER(name) = LOWER(?)", base_name)
          .or(WorkPackageCustomField.where("name ILIKE ?", "#{escaped} (%"))
          .order(:id)
      end

      def same_field?(custom_field_name, import_name)
        without_numbering(custom_field_name).casecmp?(import_name.to_s)
      end

      def without_numbering(name)
        name.to_s.sub(NUMBERING_SUFFIX, "")
      end

      def unique_name(name)
        unique_name = name
        suffix = 2
        while WorkPackageCustomField.where("LOWER(name) = LOWER(?)", unique_name).any?
          unique_name = "#{name} (#{suffix})"
          suffix += 1
        end
        unique_name
      end
    end
  end
end
