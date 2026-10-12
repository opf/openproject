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

class AdminElevationSession < ApplicationRecord
  belongs_to :user
  belongs_to :project

  enum :confirmed_with,
       { two_factor: "two_factor", password: "password", confirmation: "confirmation" },
       prefix: true,
       validate: true

  attribute :last_used_at, default: -> { Time.current }

  validates :session_id, presence: true

  scope :for_session, ->(session_id) { where(session_id:) }
  scope :active, -> { where(ended_at: nil).where(last_used_at: idle_timeout.ago..) }

  def self.idle_timeout
    Setting.admin_elevation_idle_timeout.minutes
  end

  def project_ids
    if include_subprojects?
      project.self_and_descendants.pluck(:id)
    else
      [project_id]
    end
  end

  def expires_at
    last_used_at + self.class.idle_timeout
  end

  def active?
    ended_at.nil? && expires_at.future?
  end

  def use!
    update!(last_used_at: Time.current)
  end

  def end!
    update!(ended_at: Time.current)
  end
end
