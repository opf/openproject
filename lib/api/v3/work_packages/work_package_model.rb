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

        def initialize(object, user)
          super(object)

          @user = user
          @can = WorkPackagePolicy.new(user)
        end

        # N.B. required by ActionView::Helpers::UrlHelper
        def controller; nil; end

        property :lock_version,     type: Integer
        property :subject,          type: String
        property :start_date,       type: Date
        property :due_date,         type: Date
        property :created_at,       type: DateTime
        property :updated_at,       type: DateTime
        property :category_id,      type: Integer
        property :author,           type: String
        property :project_id,       type: Integer
        property :parent_id,        type: Integer, render_nil: true
        property :responsible_id,   type: Integer
        property :assigned_to_id,   type: Integer
        property :fixed_version_id, type: Integer


        def description
          format_text(model, :description)
        end

        def raw_description
          model.description
        end

        def raw_description=(value)
          model.description = value
        end

        def type
          model.type.try(:name)
        end

        def type=(value)
          model.type = Type.find_by_name(value)
        end

        def status
          model.status.try(:name)
        end

        def status=(value)
          model.status = Status.find_by_name(value)
        end

        def priority
          model.priority.try(:name)
        end

        def priority=(value)
          model.priority = IssuePriority.find_by_name(value)
        end

        def estimated_time
          { units: I18n.t(:'datetime.units.hour', count: model.estimated_hours.to_i),
            value: model.estimated_hours }
        end

        def estimated_time=(value)
          hours = ActiveSupport::JSON.decode(value)['value']
          model.estimated_hours = hours
        end

        def version_id=(value)
          model.fixed_version_id = value
        end

        def percentage_done
          model.done_ratio
        end

        def percentage_done=(value)
          model.done_ratio = value
        end

        def author
          ::API::V3::Users::UserModel.new(model.author)  unless model.author.nil?
        end

        def responsible
          ::API::V3::Users::UserModel.new(model.responsible) unless model.responsible.nil?
        end

        def assignee
          ::API::V3::Users::UserModel.new(model.assigned_to) unless model.assigned_to.nil?
        end

        def category
          ::API::V3::Categories::CategoryModel.new(model.category)  unless model.category.nil?
        end

        def activities
          model.journals.map{ |journal| ::API::V3::Activities::ActivityModel.new(journal) }
        end

        def attachments
          model.attachments
            .map{ |attachment| ::API::V3::Attachments::AttachmentModel.new(attachment) }
        end

        def watchers
          model.watcher_users
            .order(User::USER_FORMATS_STRUCTURE[Setting.user_format])
            .map{ |u| ::API::V3::Users::UserModel.new(u) }
        end

        def relations
          relations = model.relations
          visible_relations = relations.find_all { |relation| relation.other_work_package(model).visible? }
          visible_relations.map{ |relation| RelationModel.new(relation) }
        end

        def is_closed
          model.closed?
        end

        validate :user_allowed_to_edit
        validate :user_allowed_to_edit_parent
        validate :lock_version_set
        validates_presence_of :subject, :project_id, :type, :author, :status
        validates_length_of :subject, maximum: 255
        validate :milestone_constraint
        validate :user_allowed_to_access_parent

        private

        def user_allowed_to_edit
          fail ::API::Errors::Unauthorized unless @can.allowed?(model, :edit)
        end

        def user_allowed_to_edit_parent
          if parent_changed?
            changed_model = model.dup.tap { |m| m.parent_id = parent_id }
            fail ::API::Errors::Unauthorized unless @can.allowed?(changed_model, :manage_subtasks)
          end
        end

        def lock_version_set
          fail ::API::Errors::Conflict if lock_version.nil?
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
      end
    end
  end
end
