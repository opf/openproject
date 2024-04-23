#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module BaseServices
  class BaseContracted < BaseCallable
    include Contracted
    include Shared::ServiceContext

    attr_reader :user

    def initialize(user:, contract_class: nil, contract_options: {})
      super()
      @user = user
      self.contract_class = contract_class || default_contract_class
      self.contract_options = contract_options
    end

    protected

    ##
    # Reference to a resource that we're servicing
    attr_accessor :model

    ##
    # Determine the type of context
    # this service is running in
    # e.g., within a resource lock or just executing as the given user
    def service_context(send_notifications:, &)
      in_context(model, send_notifications:, &)
    end

    def perform(params = {})
      params, send_notifications = extract(params, :send_notifications)
      service_context(send_notifications:) do
        service_call = validate_params(params)
        service_call = before_perform(params, service_call) if service_call.success?
        service_call = validate_contract(service_call) if service_call.success?
        service_call = after_validate(params, service_call) if service_call.success?
        service_call = persist(service_call) if service_call.success?
        service_call = after_perform(service_call) if service_call.success?

        service_call
      end
    end

    def extract(params, attribute)
      params = params ? params.dup : {}
      [params, params.delete(attribute)]
    end

    def validate_params(_params)
      ServiceResult.success(result: model)
    end

    def before_perform(*)
      ServiceResult.success(result: model)
    end

    def after_validate(_params, contract_call)
      contract_call
    end

    def validate_contract(call)
      success, errors = validate(model, user, options: contract_options)

      unless success
        call.success = false
        call.errors = errors
      end

      call
    end

    def after_perform(call)
      # nothing for now but subclasses can override
      call
    end

    alias_method :after_save, :after_perform

    def persist(call)
      # nothing for now but subclasses can override
      call
    end

    def default_contract_class
      raise NotImplementedError
    end

    def namespace
      self.class.name.deconstantize.pluralize
    end
  end
end
