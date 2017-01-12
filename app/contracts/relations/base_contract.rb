#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

require 'model_contract'

module Relations
  class BaseContract < ::ModelContract
    attribute :relation_type

    attribute :delay
    attribute :description

    attribute :from_id
    attribute :to_id

    validate :user_allowed_to_access
    validate :user_allowed_to_manage_relations

    attr_reader :user

    def initialize(relation, user)
      super relation

      @user = user
    end

    private

    def fields
      override_delay! super
    end

    ##
    # We have to redefine `#delay` in this `Reform::Contract::Fields` instance
    # because it's conflicting with delayed_job's `#delay`. Without this a call
    # to `fields.delay.nil?` will actually enqueue the call to `#nil?` as a delayed job
    # as opposed to just checking the field for nil.
    #
    # This is the best I could come up with. Feel free to solve this better if you know how!
    def override_delay!(fields)
      @delay_overriden ||= begin
        def fields.delay
          @table[:delay]
        end
      end

      fields
    end

    ##
    # Allow the user only to create/update relations between work packages they are allowed to see.
    def user_allowed_to_access
      errors.add :from, :error_not_found unless visible_work_packages.exists? model.from_id
      errors.add :to, :error_not_found unless visible_work_packages.exists? model.to_id
    end

    def user_allowed_to_manage_relations
      if !manage_relations?
        errors.add :base, :error_unauthorized
      end
    end

    def visible_work_packages
      ::WorkPackage.visible(user)
    end

    def manage_relations?
      user.allowed_to? :manage_work_package_relations, model.from.project
    end
  end
end
