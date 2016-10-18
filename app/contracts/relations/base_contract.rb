#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

    validate :user_allowed_to_manage_relations
    validate :user_allowed_to_access

    attr_reader :user

    def initialize(relation, user)
      super relation

      @user = user
    end

    private

    ##
    # Allow the user only to create/update relations between work packages they are allowed to see.
    def user_allowed_to_access
      if !work_packages_visible?
        errors.add :base, :error_not_found
      end
    end

    def user_allowed_to_manage_relations
      if !manage_relations?
        errors.add :base, :error_unauthorized
      end
    end

    def work_packages_visible?
      visible_work_packages.exists?(model.from_id) && visible_work_packages.exists?(model.to_id)
    end

    def visible_work_packages
      ::WorkPackage.visible(user)
    end

    def manage_relations?
      user.allowed_to? :manage_work_package_relations, model.from.project
    end
  end
end
