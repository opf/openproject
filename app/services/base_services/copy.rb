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
  class Copy < ::BaseServices::BaseContracted
    alias_attribute(:source, :model)

    def initialize(user:, source:, contract_class: nil, contract_options: { copy_source: source })
      self.source = source
      super(user: user, contract_class: contract_class, contract_options: contract_options)
    end

    def call(params)
      User.execute_as(user) do
        prepare(params)
        perform(params)
      end
    end

    def after_validate(params, _call)
      # Initialize the target resource to copy into
      call = initialize_copy(source, params)

      # Return only the unsaved copy
      return call if params[:attributes_only]

      copy_dependencies.each do |service_cls|
        next if skip_dependency?(params, service_cls)

        call.merge! call_dependent_service(service_cls, target: call.result, params: params)
      end

      call
    end

    protected

    ##
    # Should the dependency be skipped for this service run?
    def skip_dependency?(_params, _dependency_cls)
      false
    end

    ##
    # Sets up a state object that gets
    # passed around to all service calls from here
    #
    # Note that for dependent copy services to be called
    # this will already be present.
    def prepare(params)
      params[:copy_state] ||= {}
    end

    ##
    # dependent services to copy associations
    def copy_dependencies
      []
    end

    ##
    # Calls a dependent service with the source and copy instance
    def call_dependent_service(service_cls, target:, params:)
      service_cls
        .new(source: source, target: target, user: user)
        .with_state(state)
        .call(params: params)
    end

    def initialize_copy(source, params)
      raise NotImplementedError
    end

    def default_contract_class
      "#{namespace}::CopyContract".constantize
    end
  end
end
