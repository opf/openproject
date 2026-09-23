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
  class WorkflowUsageComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(workflow:, list_users: true)
      super()

      @workflow = workflow
      @list_users = list_users
    end

    private

    attr_reader :workflow

    def variants
      @variants ||= workflow.type_variants.includes(:type).in_display_order
    end

    def unused? = variants.empty?

    def list_users? = @list_users && !unused?

    def variants_only? = variants.any? { !it.is_default_variant? }

    def caption
      return I18n.t("workflows.usage.unused") if unused?
      return I18n.t("workflows.usage.used_by_variants", count: variants.size) if variants_only?

      I18n.t("workflows.usage.used_by_types", count: variants.size)
    end

    def variant_link(variant)
      render(Primer::Beta::Link.new(href: helpers.edit_type_workflow_path(**variant.path_args))) { variant.composite_name }
    end
  end
end
