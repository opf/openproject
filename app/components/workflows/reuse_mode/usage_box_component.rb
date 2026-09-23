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

module Workflows
  module ReuseMode
    class UsageBoxComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(variant:)
        super(variant)
      end

      private

      def variant = model

      def other_variants
        @other_variants ||= variant.workflow
                                   .type_variants
                                   .where.not(id: variant.id)
                                   .includes(:type)
                                   .in_display_order
      end

      def used_elsewhere? = other_variants.any?

      def scheme = used_elsewhere? ? :warning : :default

      def icon = used_elsewhere? ? :alert : :"git-branch"

      def title
        return I18n.t("workflows.reuse_mode.usage.blank.title") unless used_elsewhere?

        I18n.t("workflows.reuse_mode.usage.title", count: other_variants.size)
      end

      def description
        return I18n.t("workflows.reuse_mode.usage.blank.description") unless used_elsewhere?

        safe_join([I18n.t("workflows.reuse_mode.usage.description", count: other_variants.size),
                   safe_join(other_variants.map { variant_link(it) }, ", ")],
                  " ")
      end

      def variant_link(other)
        return render(Primer::Beta::Text.new) { other.composite_name } unless same_scope?(other)

        render(Primer::Beta::Link.new(href: url_helpers.edit_type_workflow_path(**other.path_args),
                                      scheme: :secondary,
                                      data: { turbo_frame: "_top" })) { other.composite_name }
      end

      def same_scope?(other) = other.project_id == variant.project_id
    end
  end
end
