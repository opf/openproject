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
      class WorkPackageModel < Reform::Form
        include Coercion
        include ActionView::Helpers::UrlHelper
        include OpenProject::TextFormatting
        include OpenProject::StaticRouting::UrlHelpers
        include WorkPackagesHelper

        validate :user_allowed_to_edit
        validate :user_allowed_to_edit_parent
        validate :lock_version_set
        validate :readonly_attributes_unchanged
        validates_presence_of :subject, :project_id, :type, :author, :status
        validates_length_of :subject, maximum: 255
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
          errors.add :error_conflict, '' if lock_version.nil?
        end

        def readonly_attributes_unchanged
          changed_attributes = readonly_attributes.each_with_object([]) do |a, l|
            attribute_model = (a.is_a? Hash) ? a.values[0] : a
            attribute_form = (a.is_a? Hash) ? a.keys[0] : a

            if model.respond_to?(attribute_model)
              new = send(attribute_form)
              current = model.send(attribute_model)

              new = new.id if !new.nil? && new.respond_to?(:id)
              current = current.id if !current.nil? && current.respond_to?(:id)
              new = new[:value] if new.is_a?(Hash) && new.has_key?(:value)

              l << attribute_model if new != current
            end
          end

          errors.add :error_readonly, changed_attributes unless changed_attributes.empty?
        end

        def milestone_constraint
          errors.add :parent_id, :cannot_be_milestone if model.parent && model.parent.is_milestone?
        end

        def user_allowed_to_access_parent
          errors.add(:parent_id, error_message('parent_id.does_not_exist')) if parent_changed? && !parent_visible?
        end

        def parent_changed?
          parent_id != model.parent_id
        end

        def parent_visible?
          !parent_id || ::WorkPackage.visible(@user).exists?(parent_id)
        end

        def error_message(path)
          I18n.t("activerecord.errors.models.work_package.attributes.#{path}")
        end

        def readonly_attributes
          all_attributes - [:lock_version, :subject, :parent_id, :raw_description] \
                         + [ { percentage_done: :done_ratio },
                             { estimated_time: :estimated_hours } ]
        end

        def all_attributes
          send(:fields).methods(false).grep(/[^=]$/)
        end
      end
    end
  end
end
