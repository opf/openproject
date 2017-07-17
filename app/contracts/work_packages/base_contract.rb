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

module WorkPackages
  class BaseContract < ::ModelContract
    def self.model
      WorkPackage
    end

    attribute :subject
    attribute :description
    attribute :status_id
    attribute :type_id
    attribute :priority_id
    attribute :category_id
    attribute :fixed_version_id
    attribute :lock_version
    attribute :project_id

    attribute :done_ratio,
              writeable: ->(*) {
                model.leaf? && Setting.work_package_done_ratio == 'field'
              }

    attribute :estimated_hours,
              writeable: ->(*) {
                model.leaf?
              }

    attribute :parent_id do
      if model.changed.include? 'parent_id'
        errors.add :base, :error_unauthorized unless @can.allowed?(model, :manage_subtasks)
      end
    end

    attribute :assigned_to_id do
      next unless model.project

      validate_people_visible :assignee,
                              'assigned_to_id',
                              model.project.possible_assignee_members
    end

    attribute :responsible_id do
      next unless model.project

      validate_people_visible :responsible,
                              'responsible_id',
                              model.project.possible_responsible_members
    end

    attribute :start_date,
              writeable: ->(*) {
                model.leaf?
              } do
      if start_before_parents_soonest_start?
        message = I18n.t('activerecord.errors.models.work_package.attributes.start_date.violates_parent_relationships',
                         soonest_start: Date.today + 4.days)

        errors.add :start_date, message, error_symbol: :violates_parent_relationships
      end
    end

    attribute :due_date,
              writeable: ->(*) {
                model.leaf?
              }

    def initialize(work_package, user)
      super(work_package)

      @user = user
      @can = WorkPackagePolicy.new(user)
    end

    def writable_attributes
      super + model.available_custom_fields.map { |cf| "custom_field_#{cf.id}" }
    end

    private

    attr_reader :user,
                :can

    def validate_people_visible(attribute, id_attribute, list)
      id = model[id_attribute]

      return if id.nil? || !model.changed.include?(id_attribute)

      unless principal_visible?(id, list)
        errors.add attribute,
                   I18n.t('api_v3.errors.validation.invalid_user_assigned_to_work_package',
                          property: I18n.t("attributes.#{attribute}"))
      end
    end

    def principal_visible?(id, list)
      list.exists?(user_id: id)
    end

    def start_before_parents_soonest_start?
      model.start_date &&
        model.parent &&
        model.parent.soonest_start &&
        model.start_date < model.parent.soonest_start
    end
  end
end
