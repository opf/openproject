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

class Storages::FileLinks::CreateService < BaseServices::Create
  def persist(service_result)
    if existing = find_existing(service_result.result)
      service_result.result = existing
      service_result
    else
      # create
      super
    end
  end

  private

  def after_perform(service_result)
    # This only gets called if service_result is successful
    container = service_result.result.container

    # If the container isn't journaled, no need to proceed
    return service_result unless container&.class&.journaled?

    # If journal creation fails, we don't care for now
    container.save_journals

    service_result
  end

  def find_existing(file_link)
    Storages::FileLink.find_by(
      origin_id: file_link.origin_id,
      container_id: file_link.container_id,
      container_type: file_link.container_type,
      storage_id: file_link.storage_id
    )
  end
end
