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
  module Comparison
    class CellComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(cell:)
        super()

        @cell = cell
      end

      def call
        case format
        when :plain then plain_content
        when :same_as_base then same_as_base_content
        when :mode then mode_content
        when :list then list_content
        else count_content
        end
      end

      private

      attr_reader :cell

      delegate :row, :profile, :count, :same_as_base, to: :cell

      def variant = profile.variant

      def format = row.format

      def plain_content
        case row.key
        when :availability then availability_content
        when :enabled_in_new_projects then new_project_default_content
        when :projects then projects_content
        end
      end

      def availability_content
        return global_content unless variant.project_owned?

        helpers.link_translate("types.comparison.values.project_specific",
                               i18n_args: { project: variant.project.name },
                               links: { project_url: owner_path },
                               external: false)
      end

      def global_content = muted(t("types.comparison.values.global"))

      def new_project_default_content
        return muted("-") unless variant.enabled_in_new_projects?

        render(Primer::Beta::Octicon.new(:check, color: :success))
      end

      def projects_content
        return muted(profile.project_count.to_s) if variant.project_owned? || profile.project_count.zero?

        link_text(projects_path, profile.project_count.to_s)
      end

      def same_as_base_content
        return if same_as_base.nil?
        return muted(t(:general_text_No)) unless same_as_base

        render(Primer::Beta::Octicon.new(:check,
                                         color: :success,
                                         "aria-label": t("types.comparison.values.same_as_base")))
      end

      def mode_content
        return manual_content unless linked?

        safe_join([inherited_content, link_text(source_path, source.composite_name)], " ")
      end

      def manual_content
        safe_join([render(Primer::Beta::Octicon.new(:tools, mr: 1)), t("types.edit.overview.mode.manual")])
      end

      def inherited_content
        icon = render(Primer::Beta::Octicon.new(:"arrow-down-right", color: :muted, mr: 1))

        render(Primer::Beta::Text.new(color: :muted)
                 .with_content(safe_join([icon, t("types.comparison.values.inheriting_from")])))
      end

      def list_content
        return muted("-") if count.zero?

        plain_text(cell.labels.to_sentence)
      end

      def count_content = plain_text(count.to_s)

      def linked? = variant.linked?(row.aspect)

      def source = variant.source_for(row.aspect)

      def source_path = helpers.aspect_edit_path(source, row.aspect)

      def projects_path = edit_type_projects_path(**variant.path_args)

      def owner_path = project_settings_work_packages_types_path(variant.project)

      def muted(value) = render(Primer::Beta::Text.new(color: :muted).with_content(value))

      def plain_text(value) = render(Primer::Beta::Text.new.with_content(value))

      def link_text(href, value) = render(Primer::Beta::Link.new(href:).with_content(value))
    end
  end
end
