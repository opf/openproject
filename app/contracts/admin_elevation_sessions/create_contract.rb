# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module AdminElevationSessions
  class CreateContract < ::ModelContract
    attribute :project
    attribute :session_id
    attribute :include_subprojects
    attribute :confirmed_with

    validate :feature_active
    validate :user_is_active_admin
    validate :project_is_active
    validate :password_confirmed_if_checkable

    private

    def password_confirmed_if_checkable
      return unless model.confirmed_with_confirmation? && user.password_checkable?

      errors.add(:base, :password_required)
    end

    def feature_active
      return if OpenProject::FeatureDecisions.admin_privilege_elevation_active?

      errors.add(:base, :feature_disabled)
    end

    def user_is_active_admin
      errors.add(:base, :error_unauthorized) unless user.active_admin?
    end

    def project_is_active
      return if model.project.nil? || model.project.active?

      errors.add(:project, :archived)
    end
  end
end
