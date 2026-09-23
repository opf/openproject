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
    class ModeBoxComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(variant:)
        super(variant)
      end

      private

      def variant = model

      def workflow = variant.workflow

      def shared? = !workflow.used_by_one_variant?

      def scheme = shared? ? :info : :default

      def icon = shared? ? :link : :pencil

      def title
        return I18n.t("workflows.reuse_mode.independent.title") unless shared?

        naming("workflows.reuse_mode.shared.title")
      end

      def description
        return naming("workflows.reuse_mode.independent.description") unless shared?

        I18n.t("workflows.reuse_mode.shared.description")
      end

      def administration? = variant.project_id.nil?

      def naming(key)
        return I18n.t(key, name: workflow.name).gsub(helpers.link_regex, '\2') unless administration?

        helpers.link_translate(key,
                               i18n_args: { name: workflow.name },
                               links: { workflow_url: url_helpers.edit_workflow_path(workflow) },
                               external: false,
                               data: { turbo_frame: "_top", test_selector: "workflow-mode-name" })
      end

      def change_dialog_path = url_helpers.change_dialog_type_workflow_path(**variant.path_args)

      def create_dialog_path = url_helpers.create_dialog_type_workflow_path(**variant.path_args)
    end
  end
end
