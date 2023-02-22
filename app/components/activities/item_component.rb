# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

class Activities::ItemComponent < ViewComponent::Base
  with_collection_parameter :event

  def initialize(event:, display_user: true)
    super()
    @event = event
    @display_user = display_user
  end

  def display_belonging_project?
    @event.journal.journable_type != 'Project'
  end

  def display_user?
    @display_user
  end

  def display_details?
    return false if @event.journal.initial?

    rendered_details.present?
  end

  def rendered_details
    @rendered_details ||=
      @event.journal
        .details
        .flat_map { |detail| @event.journal.render_detail(detail) }
  end

  def format_activity_title(text)
    helpers.truncate_single_line(text, length: 100)
  end

  def comment
    return unless work_package?

    @event.event_description
  end

  def description
    return if work_package?

    @event.event_description
  end

  def work_package?
    @event.journal.journable_type == "WorkPackage"
  end
end
