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

module DebounceableJob
  # This module is generalizes the debounce logic that was originally used on {Storages::ManageStorageIntegrationsJob}
  # Basically it ensures that a thread only queues one job per interval.

  # it depends on the class method `key` being implemented. The method will receive all the arguments
  # used to invoke the job to construct the RequestStore key.
  SINGLE_THREAD_DEBOUNCE_TIME = 4.seconds

  def debounce(*, **)
    store_key = key(*, **)
    timestamp = RequestStore.store[store_key]

    return false if timestamp.present? && (timestamp + SINGLE_THREAD_DEBOUNCE_TIME) > Time.current

    result = set(wait: 5.seconds).perform_later(*, **)
    RequestStore.store[store_key] = Time.current
    result
  end
end
