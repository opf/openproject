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
  class Write < BaseContracted
    protected

    def persist(service_result)
      service_result = super(service_result)

      unless service_result.result.save
        service_result.errors = service_result.result.errors
        service_result.success = false
      end

      service_result
    end

    # Validations are already handled in the SetAttributesService
    # and thus we do not have to validate again.
    def validate_contract(service_result)
      service_result
    end

    def before_perform(params)
      set_attributes(params)
    end

    def set_attributes(params)
      attributes_service_class
        .new(user: user,
             model: instance(params),
             contract_class: contract_class,
             contract_options: contract_options)
        .call(params)
    end

    def attributes_service_class
      "#{namespace}::SetAttributesService".constantize
    end

    def instance(_params)
      raise NotImplementedError
    end

    def default_contract_class
      raise NotImplementedError
    end

    def instance_class
      namespace.singularize.constantize
    end
  end
end
