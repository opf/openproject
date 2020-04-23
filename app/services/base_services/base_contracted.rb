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

module BaseServices
  class BaseContracted
    include Contracted
    include Shared::ServiceContext

    attr_reader :user

    def initialize(user:, contract_class: nil, contract_options: {})
      @user = user
      self.contract_class = contract_class || default_contract_class
      self.contract_options = contract_options
    end

    def call(params = nil)
      in_context(model, true) do
        perform(params)
      end
    end

    private

    def perform(params)
      service_call = before_perform(params)

      service_call = validate_contract(service_call) if service_call.success?
      service_call = after_validate(params, service_call) if service_call.success?
      service_call = persist(service_call) if service_call.success?
      service_call = after_perform(service_call) if service_call.success?

      service_call
    end

    def before_perform(_params)
      ServiceResult.new(success: true, result: model)
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
