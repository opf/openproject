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

require 'work_packages/base_contract'

module WorkPackages
  class CreateContract < BaseContract
    attribute :author_id,
              writeable: false do
      errors.add :author_id, :invalid if model.author != user
    end

    default_attribute_permission :add_work_packages

    def validate
      user_allowed_to_add

      super
    end

    private

    def user_allowed_to_add
      if (model.project && !@user.allowed_to?(:add_work_packages, model.project)) ||
         !@user.allowed_to?(:add_work_packages, nil, global: true)

        errors.add :base, :error_unauthorized
      end
    end

    def attributes_changed_by_user
      # lock version is initialized by AR itself
      super - ['lock_version']
    end
  end
end
