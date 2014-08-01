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
        include Composition
        include Coercion
        include ActionView::Helpers::UrlHelper
        include OpenProject::TextFormatting
        include OpenProject::StaticRouting::UrlHelpers
        include WorkPackagesHelper
        include GravatarImageTag

        # N.B. required by ActionView::Helpers::UrlHelper
        def controller; nil; end

        model :work_package

        property :subject, on: :work_package, type: String
        property :start_date, on: :work_package, type: Date
        property :due_date, on: :work_package, type: Date
        property :created_at, on: :work_package, type: DateTime
        property :updated_at, on: :work_package, type: DateTime
        property :author, on: :work_package, type: String
        property :project_id, on: :work_package, type: Integer
        property :responsible_id, on: :work_package, type: Integer
        property :assigned_to_id, on: :work_package, type: Integer
        property :fixed_version_id, on: :work_package, type: Integer

        def work_package
          model[:work_package]
        end

        def description
          format_text(work_package, :description)
        end

        def raw_description
          work_package.description
        end

        def raw_description=(value)
          work_package.description = value
        end

        def type
          work_package.type.try(:name)
        end

        def type=(value)
          type = Type.find(:first, conditions: ['name ilike ?', value])
          work_package.type = type
        end

        def status
          work_package.status.try(:name)
        end

        def status=(value)
          status = Status.find(:first, conditions: ['name ilike ?', value])
          work_package.status = status
        end

        def priority
          work_package.priority.try(:name)
        end

        def priority=(value)
          priority = IssuePriority.find(:first, conditions: ['name ilike ?', value])
          work_package.priority = priority
        end

        def estimated_time
          { units: 'hours', value: work_package.estimated_hours }
        end

        def estimated_time=(value)
          hours = ActiveSupport::JSON.decode(value)['value']
          work_package.estimated_hours = hours
        end

        def version_id=(value)
          work_package.fixed_version_id = value
        end

        def percentage_done
          work_package.done_ratio
        end

        def percentage_done=(value)
          work_package.done_ratio = value
        end

        def author
          ::API::V3::Users::UserModel.new(work_package.author)  unless work_package.author.nil?
        end

        def responsible
          ::API::V3::Users::UserModel.new(work_package.responsible) unless work_package.responsible.nil?
        end

        def assignee
          ::API::V3::Users::UserModel.new(work_package.assigned_to) unless work_package.assigned_to.nil?
        end

        def activities
          work_package.journals.map{ |journal| ::API::V3::Activities::ActivityModel.new(journal) }
        end

        def attachments
          work_package.attachments
            .map{ |attachment| ::API::V3::Attachments::AttachmentModel.new(attachment) }
        end

        def watchers
          work_package.watcher_users
            .order(User::USER_FORMATS_STRUCTURE[Setting.user_format])
            .map{ |u| ::API::V3::Users::UserModel.new(u) }
        end

        def relations
          relations = work_package.relations
          visible_relations = relations.find_all { |relation| relation.other_work_package(work_package).visible? }
          visible_relations.map{ |relation| RelationModel.new(relation) }
        end

        def is_closed
          work_package.closed?
        end

        validates_presence_of :subject, :project_id, :type, :author, :status
        validates_length_of :subject, maximum: 255
      end
    end
  end
end
