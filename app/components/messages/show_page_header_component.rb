# frozen_string_literal: true

# -- copyright
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
# ++

module Messages
  class ShowPageHeaderComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper
    include WatchersHelper

    def initialize(topic:)
      super
      @topic = topic
    end

    def breadcrumb_items
      [
        { href: project_overview_path(project.id), text: project.name },
        { href: project_forums_path(project), text: t(:label_forum_plural) },
        { href: project_forum_path(project, forum), text: forum.name },
        @topic.subject
      ]
    end

    private

    def forum = @topic.forum

    def project = forum.project

    def summary
      parts = [started, t("forums.topic.replies", count: @topic.replies_count)]
      parts << t("forums.topic.participants", count: participants_count) if participants_count.positive?
      safe_join(parts + created_work_package_info_lines, " · ")
    end

    def created_work_package_info_lines
      Messages::CreatedWorkPackagesQuery.for_topic(@topic, user: User.current).map do |work_package|
        render(WorkPackages::InfoLineComponent.new(work_package:))
      end
    end

    def started
      t("forums.topic.started_html", time: render(OpPrimer::RelativeTimeComponent.new(datetime: @topic.created_at, prefix: "")))
    end

    def participants_count
      @participants_count ||= Message.where(id: @topic.id).or(Message.where(parent_id: @topic.id)).distinct.count(:author_id)
    end
  end
end
