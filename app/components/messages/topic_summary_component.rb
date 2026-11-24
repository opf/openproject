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

module Messages
  class TopicSummaryComponent < ApplicationComponent
    include OpTurbo::Streamable

    def initialize(topic:)
      super()
      @topic = topic
    end

    def wrapper_uniq_by = @topic.id

    def call
      component_wrapper(tag: :span, class: "d-flex flex-wrap flex-items-center op-forum-topic-summary") do
        parts = [started, t("forums.topic.replies", count: @topic.replies_count)]
        parts << t("forums.topic.participants", count: participants_count) if participants_count.positive?
        safe_join([solved_icon, safe_join(parts + created_work_package_info_lines, " · ")].compact)
      end
    end

    private

    def started
      t("forums.topic.started_html", time: render(OpPrimer::RelativeTimeComponent.new(datetime: @topic.created_at, prefix: "")))
    end

    def solved_icon
      return unless @topic.accepted_solutions.exists?

      render(AcceptedSolutionIconComponent.new(kind: AcceptedSolutionIconComponent::TOPIC))
    end

    def created_work_package_info_lines
      Messages::CreatedWorkPackagesQuery.for_topic(@topic, user: User.current).map do |work_package|
        render(WorkPackages::InfoLineComponent.new(work_package:))
      end
    end

    def participants_count
      @participants_count ||= Message.where(id: @topic.id).or(Message.where(parent_id: @topic.id)).distinct.count(:author_id)
    end
  end
end
