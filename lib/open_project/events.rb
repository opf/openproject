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

module OpenProject
  ##
  # Events defined in OpenProject, e.g. created work packages.
  # The module defines a constant for each event.
  #
  # Plugins should register their events here too by prepending a module
  # including the respective constants.
  #
  # @note Does not include all events but it should!
  # @see OpenProject::Notifications
  module Events
    AGGREGATED_WORK_PACKAGE_JOURNAL_READY = "aggregated_work_package_journal_ready".freeze
    AGGREGATED_WIKI_JOURNAL_READY = "aggregated_wiki_journal_ready".freeze

    JOURNAL_CREATED = 'journal_created'.freeze

    MEMBER_CREATED = 'member_created'.freeze
    MEMBER_UPDATED = 'member_updated'.freeze
    # Called like this for historic reasons, should be called 'member_destroyed'
    MEMBER_DESTROYED = 'member_removed'.freeze

    TIME_ENTRY_CREATED = "time_entry_created".freeze

    PROJECT_CREATED = "project_created".freeze
    PROJECT_UPDATED = "project_updated".freeze
    PROJECT_RENAMED = "project_renamed".freeze

    WATCHER_ADDED = 'watcher_added'.freeze
    WATCHER_REMOVED = 'watcher_removed'.freeze
  end
end
