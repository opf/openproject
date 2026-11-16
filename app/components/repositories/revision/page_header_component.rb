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

module Repositories
  module Revision
    class PageHeaderComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers

      def initialize(changeset:, repository:, project: nil)
        super
        @project = project
        @changeset = changeset
        @repository = repository
      end

      def previous_button_present?
        @previous_button_present ||= @changeset.previous.present?
      end

      def next_button_present?
        @next_button_present ||= @changeset.next.present?
      end

      def previous_button_disabled?
        !previous_button_present?
      end

      def next_button_disabled?
        !next_button_present?
      end

      def previous_button_url
        return nil unless previous_button_present?

        url_for(controller: "/repositories", action: "revision", project_id: @project, rev: @changeset.previous.identifier)
      end

      def next_button_url
        return nil unless next_button_present?

        url_for(controller: "/repositories", action: "revision", project_id: @project, rev: @changeset.next.identifier)
      end

      def previous_button_tag
        previous_button_present? ? :a : :button
      end

      def next_button_tag
        next_button_present? ? :a : :button
      end

      def previous_button_title
        previous_button_present? ? t(:label_revision_id, value: helpers.format_revision(@changeset.previous)) : t(:label_previous)
      end

      def next_button_title
        previous_button_present? ? t(:label_revision_id, value: helpers.format_revision(@changeset.next)) : t(:label_next)
      end
    end
  end
end
