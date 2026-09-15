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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  class VariantComparison
    # One variant's compared configuration, fully resolved so no row of the matrix reaches the
    # database.
    Profile = Data.define(:variant, :fields, :required, :group_names, :excluded,
                          :statuses, :transitions, :roles, :project_count) do
      delegate :id, to: :variant

      def base? = variant.is_default_variant?

      def custom_fields = fields.select { it.kind == :custom_field }

      def builtin_fields = fields.reject { it.kind == :custom_field }

      # What makes two variants interchangeable. Which projects use a variant is not part of it:
      # two variants differing only in that are duplicates.
      def digest = [form_digest, workflow_digest]

      def digest_for(aspect)
        case aspect
        when TypeVariant::FORM_CONFIGURATION then form_digest
        when TypeVariant::WORKFLOWS then workflow_digest
        end
      end

      # Group names stay ordered: the same fields arranged into different sections are a
      # different form.
      def form_digest = [group_names, fields.map(&:key).sort, required.map(&:key).sort]

      def workflow_digest = [statuses.map(&:id).sort, transitions.sort]
    end
  end
end
