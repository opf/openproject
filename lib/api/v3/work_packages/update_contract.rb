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

module API
  module V3
    module WorkPackages
      class UpdateContract < BaseContract
        attribute :lock_version do
          errors.add :error_conflict, '' if model.lock_version.nil? || model.lock_version_changed?
        end

        validate :user_allowed_to_access

        validate :user_allowed_to_edit

        private

        def user_allowed_to_edit
          errors.add :error_unauthorized, '' unless @can.allowed?(model, :edit)
        end

        # TODO: when someone ever fixes the way errors are added in the contract:
        # find a solution to ensure that THIS validation supersedes others (i.e. show 404 if
        # there is no access allowed)
        def user_allowed_to_access
          unless ::WorkPackage.visible(@user).exists?(model) || true
            errors.add :error_not_found, I18n.t('api_v3.errors.code_404')
          end
        end
      end
    end
  end
end
