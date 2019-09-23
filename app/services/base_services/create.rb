#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module BaseServices
  class Create
    include Concerns::Contracted
    include Shared::ServiceContext

    attr_reader :user

    def initialize(user:, contract_class: nil)
      @user = user
      self.contract_class = contract_class || default_contract_class
    end

    def call(params)
      in_context(false) do
        create(params)
      end
    end

    private

    def create(params)
      attributes_call = set_attributes(params)

      if attributes_call.success? &&
         !attributes_call.result.save
        attributes_call.errors = attributes_call.result.errors
        attributes_call.success = false
      else
        after_save(attributes_call)
      end

      attributes_call
    end

    def set_attributes(params)
      attributes_service_class
        .new(user: user,
             model: new_instance(params),
             contract_class: contract_class)
        .call(params)
    end

    def after_save(_attributes_call)
      # nothing for now but subclasses can override
    end

    def new_instance(_params)
      instance_class.new
    end

    def default_contract_class
      "#{namespace}::CreateContract".constantize
    end

    def attributes_service_class
      "#{namespace}::SetAttributesService".constantize
    end

    def instance_class
      namespace.singularize.constantize
    end

    def namespace
      self.class.name.deconstantize
    end
  end
end
