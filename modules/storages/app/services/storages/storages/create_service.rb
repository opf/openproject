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
# See COPYRIGHT and LICENSE files for more details.
#++

# This is the factored-out business logic for creating a new Storage object.
# It returns a service result object with the created object and error messages.
# A lot of functionality around creating objects repeats and is handled in the
# BaseService::Create functionality and in the SetAttributes service, so this
# file only contains the functionality specific for creation.
# Called by: This service is called from the storages_controller.rb in order to create a new Storage.
# The namespace here is Storage_s_, because ToDo: Why Storages::Storage_s_ module?
# Reference: ToDo: Link to documentation on services
# The comments here are also referenced from the other *_service.rb files in the module.
module Storages::Storages
  class CreateService < ::BaseServices::Create
    protected

    # Override the "creator_id" parameter with the actual user.
    # before_perform is called in the service before attributes are set.
    def before_perform(params, _service_result)
      params[:creator_id] = user.id
      super(params, _service_result)
    end
  end
end
