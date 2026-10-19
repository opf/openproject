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
  class AcceptedSolutionsBannerComponent < ApplicationComponent
    def initialize(topic:)
      super()
      @topic = topic
    end

    def render? = solutions.any?

    def call
      render(Primer::Alpha::Banner.new(scheme: :success, icon: AcceptedSolutionIconComponent::ICON, mt: 3,
                                       test_selector: "accepted-solutions-banner")) do
        safe_join([t("forums.topic.accepted_solutions_banner", count: solutions.size), links], " ")
      end
    end

    private

    def solutions
      @solutions ||= @topic.accepted_solutions.to_a
    end

    def links
      safe_join(solutions.map { link(it) }, " · ")
    end

    def link(reply)
      render(Primer::Beta::Link.new(href: helpers.message_anchor_path(reply), data: { turbo: false })) do
        [reply.author&.name, helpers.format_date(reply.created_at)].compact.join(", ")
      end
    end
  end
end
