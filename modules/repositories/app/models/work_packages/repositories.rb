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

module WorkPackages::Repositories
  extend ActiveSupport::Concern

  included do
    has_many :repository_branches, dependent: :destroy, class_name: "Repositories::Branch"
    has_and_belongs_to_many :repository_commits,
                            class_name: "Repositories::Commit",
                            association_foreign_key: "repository_commit_id"
    has_and_belongs_to_many :repository_issues,
                            class_name: "Repositories::Issue",
                            association_foreign_key: "repository_issue_id"
    has_and_belongs_to_many :repository_merge_requests,
                            class_name: "Repositories::MergeRequest",
                            association_foreign_key: "repository_merge_request_id"
  end
end
