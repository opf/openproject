#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

OpenProject::Activity.map do |activity|
  activity.register :work_packages, class_name: '::Activities::WorkPackageActivityProvider'
  activity.register :changesets, class_name: 'Activities::ChangesetActivityProvider'
  activity.register :news, class_name: 'Activities::NewsActivityProvider',
                           default: false
  activity.register :wiki_edits, class_name: 'Activities::WikiContentActivityProvider',
                                 default: false
  activity.register :messages, class_name: 'Activities::MessageActivityProvider',
                               default: false
  activity.register :time_entries, class_name: 'Activities::TimeEntryActivityProvider',
                                   default: false
end

Project.register_latest_project_activity on: 'WorkPackage',
                                         attribute: :updated_at

Project.register_latest_project_activity on: 'News',
                                         attribute: :updated_at

Project.register_latest_project_activity on: 'Changeset',
                                         chain: 'Repository',
                                         attribute: :committed_on

Project.register_latest_project_activity on: 'WikiContent',
                                         chain: %w(Wiki WikiPage),
                                         attribute: :updated_on

Project.register_latest_project_activity on: 'Message',
                                         chain: 'Forum',
                                         attribute: :updated_on

Project.register_latest_project_activity on: 'TimeEntry',
                                         attribute: :updated_on
