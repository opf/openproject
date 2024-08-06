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

require_relative "../constants/open_project/project_latest_activity"

Rails.application.reloader.to_prepare do
  OpenProject::Activity.map do |activity|
    activity.register :work_packages, class_name: "::Activities::WorkPackageActivityProvider"
    activity.register :project_attributes, class_name: "Activities::ProjectActivityProvider",
                                           default: false
    activity.register :changesets, class_name: "Activities::ChangesetActivityProvider"
    activity.register :news, class_name: "Activities::NewsActivityProvider",
                             default: false
    activity.register :wiki_edits, class_name: "Activities::WikiPageActivityProvider",
                                   default: false
    activity.register :messages, class_name: "Activities::MessageActivityProvider",
                                 default: false
  end

  OpenProject::ProjectLatestActivity.register on: "WorkPackage"

  OpenProject::ProjectLatestActivity.register on: "Project",
                                              project_id_attribute: :id

  OpenProject::ProjectLatestActivity.register on: "Changeset",
                                              chain: "Repository",
                                              attribute: :committed_on

  OpenProject::ProjectLatestActivity.register on: "News"

  OpenProject::ProjectLatestActivity.register on: "WikiPage",
                                              chain: %w(Wiki)

  OpenProject::ProjectLatestActivity.register on: "Message",
                                              chain: "Forum"
end
