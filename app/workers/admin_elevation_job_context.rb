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

# Jobs load their user anew, so the admin elevation of the user enqueuing the job is captured
# with the job and handed to that same user while the job runs.
module AdminElevationJobContext
  extend ActiveSupport::Concern

  included do
    # Has to be declared after SharedJobSetup, which clears the RequestStore around the job.
    around_perform :with_admin_elevation_context
  end

  def initialize(...)
    super
    @admin_elevation_context = capture_admin_elevation_context
  end

  def serialize
    super.merge("admin_elevation" => @admin_elevation_context)
  end

  def deserialize(job_data)
    super
    @admin_elevation_context = job_data["admin_elevation"]
  end

  private

  def capture_admin_elevation_context
    user = User.current
    return inherited_admin_elevation_context unless user.admin?

    { "user_id" => user.id, "elevation" => user.admin_elevation.to_h }
  end

  def inherited_admin_elevation_context
    user_id, elevation = RequestStore.store.fetch(:admin_elevations, {}).first
    { "user_id" => user_id, "elevation" => elevation.to_h } if user_id
  end

  def with_admin_elevation_context
    if @admin_elevation_context
      elevation = Users::AdminElevation.from_h(@admin_elevation_context["elevation"])
      RequestStore[:admin_elevations] = { @admin_elevation_context["user_id"] => elevation }
    end

    yield
  end
end
