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

# The logic for creating storage was extracted from the controller and put into
# a service: https://dev.to/joker666/ruby-on-rails-pattern-service-objects-b19
# Purpose: create and persist a Storages::Storage record
# Used by: Storages::Admin::StoragesController#create, could also be used by the
# API in the future.
# The comments here are also valid for the other *_service.rb files
module Storages::Storages
  class CreateService < ::BaseServices::Create
    protected

    def after_perform(service_call)
      super

      storage = service_call.result
      # Automatically create an OAuthApplication object for the Nextcloud storage
      # using values from storage (particularly :host) as defaults
      if storage.provider_type_nextcloud?
        persist_service_result = ::Storages::OAuthApplications::CreateService.new(storage:, user:).call
        storage.oauth_application = persist_service_result.result if persist_service_result.success?
        service_call.add_dependent!(persist_service_result)
      end

      service_call
    end

    # @override BaseServices::Create#instance to return a Storages::{ProviderType}Storage class name
    # At this stage, the model contract has already been validated, so we can be sure of the provider_type presence
    # @example instance_klass = Storages::NextcloudStorage
    #
    def instance(params)
      instance_klass = params[:provider_type].constantize
      instance_klass.new
    end
  end
end
