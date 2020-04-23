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
  class SetAttributes
    include Contracted

    def initialize(user:, model:, contract_class:, contract_options: {})
      self.user = user
      self.model = model

      self.contract_class = contract_class
      self.contract_options = contract_options
    end

    def call(params)
      set_attributes(params)

      validate_and_result
    end

    private

    attr_accessor :user,
                  :model,
                  :contract_class

    def set_attributes(params)
      model.attributes = params

      set_default_attributes(params) if model.new_record?
    end

    def set_default_attributes(_params)
      # nothing to do for now but a subclass may
    end

    def validate_and_result
      success, errors = validate(model, user, options: contract_options)

      ServiceResult.new(success: success,
                        errors: errors,
                        result: model)
    end
  end
end
