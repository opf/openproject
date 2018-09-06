#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module Concerns::Contracted
  extend ActiveSupport::Concern

  included do
    attr_reader :contract_class

    def contract_class=(cls)
      unless cls <= ::ModelContract
        raise ArgumentError "#{cls.name} is not an instance of ModelContract."
      end

      @contract_class = cls
    end

    private

    def instantiate_contract(object, user)
      contract_class.new(object, user)
    end

    def validate_and_save(object, user)
      validate_and_yield(object, user) do
        object.save
      end
    end

    ##
    # Call the given block and assume object is erroneous if
    # it does not return truthy
    def validate_and_yield(object, user)
      contract = instantiate_contract(object, user)

      if !contract.validate
        [false, contract.errors]
      elsif !yield
        [false, object.errors]
      else
        [true, object.errors]
      end
    end

    def validate(object, user)
      validate_and_yield(object, user) do
        object.valid?
      end
    end
  end
end
