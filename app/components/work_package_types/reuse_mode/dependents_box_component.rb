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
  module ReuseMode
    class DependentsBoxComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(variant:, aspect:)
        @aspect = aspect
        super(variant)
      end

      private

      attr_reader :aspect

      def variant = model

      def dependents_count
        @dependents_count ||= variant.dependents_for(aspect).count(:all)
      end

      def any_dependents? = dependents_count.positive?

      def scheme = any_dependents? ? :warning : :default

      def icon = any_dependents? ? :alert : :"git-branch"

      def title
        return t("types.edit.reuse_mode.dependents.blank.title") unless any_dependents?

        t("types.edit.reuse_mode.dependents.title", count: dependents_count)
      end

      def description
        return t("types.edit.reuse_mode.dependents.blank.description") unless any_dependents?

        t("types.edit.reuse_mode.dependents.description", count: dependents_count)
      end

      def dialog_path
        type_configuration_dependents_dialog_path(**variant.path_args, aspect:)
      end
    end
  end
end
