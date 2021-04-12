#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class GithubCheckRun < ApplicationRecord
  STATES = %w[queued in_progress completed].freeze
  CONCLUSIONS = %w[action_required cancelled failure neutral success skipped stale timed_out].freeze

  belongs_to :github_pull_request, touch: true

  validates_presence_of :github_app_owner_avatar_url,
                        :github_html_url,
                        :github_id,
                        :status,
                        :name
  validates :status, inclusion: { in: STATES }
  validates :conclusion, inclusion: { in: CONCLUSIONS }, allow_nil: true
end
