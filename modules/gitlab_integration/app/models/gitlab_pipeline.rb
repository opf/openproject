#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class GitlabPipeline < ApplicationRecord
  belongs_to :gitlab_merge_request, touch: true

  # TODO: confirm with the gitlab documentation what are the different statuses.
  enum status: {
    created: "created",
    running: "running",
    success: "success",
    waiting: "waiting",
    preparing: "preparing",
    failed: "failed",
    pending: "pending",
    canceled: "canceled",
    skipped: "skipped",
    manual: "manual",
    scheduled: "scheduled"
  }

  validates_presence_of :gitlab_user_avatar_url,
                        :gitlab_html_url,
                        :gitlab_id,
                        :status,
                        :name,
                        :ci_details,
                        :commit_id,
                        :username
end
