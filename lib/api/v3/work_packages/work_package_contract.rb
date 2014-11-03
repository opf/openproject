#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

require 'reform'
require 'reform/form/coercion'

module API
  module V3
    module WorkPackages
      class WorkPackageContract < Reform::Contract
        WRITEABLE_ATTRIBUTES = ['lock_version', 'subject', 'parent_id', 'description'].freeze

        def initialize(object, user)
          super(object)

          @user = user
          @can = WorkPackagePolicy.new(user)
        end

        property :subject
        property :project
        property :type
        property :author
        property :status

        validates :subject, presence: true, length: { maximum: 255 }
        validates :project, presence: true
        validates :type, presence: true
        validates :author, presence: true
        validates :status, presence: true

        validate :user_allowed_to_edit
        validate :user_allowed_to_edit_parent
        validate :lock_version_set
        validate :readonly_attributes_unchanged
        validate :milestone_constraint
        validate :user_allowed_to_access_parent

        private

        def user_allowed_to_edit
          errors.add :error_unauthorized, '' unless @can.allowed?(model, :edit)
        end

        def user_allowed_to_edit_parent
          errors.add :error_unauthorized, '' unless @can.allowed?(model, :manage_subtasks) if parent_changed?
        end

        def lock_version_set
          errors.add :error_conflict, '' if model.lock_version.nil?
        end

        def readonly_attributes_unchanged
          changed_attributes = model.changed - WRITEABLE_ATTRIBUTES

          errors.add :error_readonly, changed_attributes unless changed_attributes.empty?
        end

        def milestone_constraint
          errors.add :parent_id, :cannot_be_milestone if model.parent && model.parent.is_milestone?
        end

        def user_allowed_to_access_parent
          errors.add(:parent_id, error_message('parent_id.does_not_exist')) if parent_changed? && !parent_visible?
        end

        def parent_changed?
          model.changed.include? 'parent_id'
        end

        def parent_visible?
          !model.parent_id || ::WorkPackage.visible(@user).exists?(model.parent_id)
        end

        def error_message(path)
          I18n.t("activerecord.errors.models.work_package.attributes.#{path}")
        end
      end
    end
  end
end
