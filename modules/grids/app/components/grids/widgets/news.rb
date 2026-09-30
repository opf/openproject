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

module Grids
  module Widgets
    class News < Grids::WidgetComponent
      NEWS_LIMIT = 5
      private_constant :NEWS_LIMIT

      param :project, optional: true

      option :limit, default: -> { NEWS_LIMIT }

      def newest
        @newest ||= news.limit(limit).to_a
      end

      def news
        @news ||=
          if project_scoped?
            project.news.visible(current_user).newest_first
          else
            ::News
              .visible(current_user)
              .newest_first
              .includes(:project)
          end
      end

      def title
        Project.human_attribute_name(:news)
      end

      def render?
        global_scoped? || project.module_enabled?("news")
      end

      private

      def project_scoped? = project.present?

      def global_scoped? = !project_scoped?

      def can_manage_news?
        current_user.allowed_in_project?(:manage_news, project)
      end
    end
  end
end
