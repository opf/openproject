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
  class SetAttributes
    include Concerns::Contracted

    def initialize(user:, model:, contract_class:)
      self.user = user
      self.model = model

      # Allow tracking changes caused by a user but done for him by the system.
      # E.g. fixed_version of a work package might need to be changed as the user changed the project.
      # This is currently used for permission checks where the changed project is checked but the fixed_version
      # is not if it is done by the system.
      model.extend(Mixins::ChangedBySystem)

      self.contract_class = contract_class
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

      set_default_attributes if model.new_record?
    end

    def set_default_attributes
      # nothing to do for now but a subclass may
    end

    def validate_and_result
      success, errors = validate(model, user)

      ServiceResult.new(success: success,
                        errors: errors,
                        result: model)
    end
  end
end
