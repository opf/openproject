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
  module FormConfiguration
    class ReconcileEditorRecordsService
      include LayoutLock

      def initialize(form)
        @form = form
      end

      # Default groups first: GenerateDefaultsService refuses once memberships
      # exist, and memberships without groups read as an intentionally empty form.
      def call
        materialize_default_groups if unconfigured?
        EnsureAttributeMembershipService.new(form).call
      end

      private

      attr_reader :form

      def unconfigured?
        !form.form_groups.exists? && !form.form_attributes.exists?
      end

      def materialize_default_groups
        with_layout_lock(form) do
          unconfigured? ? GenerateDefaultsService.new(form, from: defaults_source).call : ServiceResult.success(result: form)
        end
      end

      def defaults_source
        variants = form.type_variants.reload.to_a
        return form if variants.map(&:default_attribute_groups).uniq.size != 1

        variants.first
      end
    end
  end
end
