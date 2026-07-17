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

module WorkPackageTypes
  module Patterns
    class TokenPropertyMapper
      STRING_OR_NIL = ->(v) { v&.to_s }
      ARRAY = ->(v) { v.compact.presence&.join(", ") }
      DATE = ->(v) { v&.strftime(Setting.date_format || "%Y-%m-%d") }
      DURATION = ->(v) { DurationConverter.output(v) }

      class << self
        def attribute(key, label_fn, value_fn, formatter = STRING_OR_NIL)
          AttributeToken.new(key, label_fn, value_fn, formatter)
        end
      end
      # rubocop:disable Layout/LineLength
      BASE_ATTRIBUTE_TOKENS = [
        attribute(:id, -> { WorkPackage.human_attribute_name(:id) }, ->(wp) { wp.id }),
        attribute(:accountable, -> { WorkPackage.human_attribute_name(:responsible) }, ->(wp) { wp.responsible }),
        attribute(:assignee, -> { WorkPackage.human_attribute_name(:assigned_to) }, ->(wp) { wp.assigned_to }),
        attribute(:author, -> { WorkPackage.human_attribute_name(:author) }, ->(wp) { wp.author }),
        attribute(:category, -> { WorkPackage.human_attribute_name(:category) }, ->(wp) { wp.category }),
        attribute(:creation_date, -> { WorkPackage.human_attribute_name(:created_at) }, ->(wp) { wp.created_at }, DATE),
        attribute(:estimated_time, -> { WorkPackage.human_attribute_name(:estimated_hours) }, ->(wp) { wp.estimated_hours }, DURATION),
        attribute(:remaining_time, -> { WorkPackage.human_attribute_name(:remaining_hours) }, ->(wp) { wp.remaining_hours }, DURATION),
        attribute(:finish_date, -> { WorkPackage.human_attribute_name(:due_date) }, ->(wp) { wp.due_date }, DATE),
        attribute(:parent_id, -> { WorkPackage.human_attribute_name(:id) }, ->(parent) { parent.id }),
        attribute(:parent_assignee, -> { WorkPackage.human_attribute_name(:assigned_to) }, ->(parent) { parent.assigned_to }),
        attribute(:parent_author, -> { WorkPackage.human_attribute_name(:author) }, ->(parent) { parent.author }),
        attribute(:parent_category, -> { WorkPackage.human_attribute_name(:category) }, ->(parent) { parent.category }),
        attribute(:parent_creation_date, -> { WorkPackage.human_attribute_name(:created_at) }, ->(parent) { parent.created_at }, DATE),
        attribute(:parent_estimated_time, -> { WorkPackage.human_attribute_name(:estimated_hours) }, ->(parent) { parent.estimated_hours }, DURATION),
        attribute(:parent_remaining_time, -> { WorkPackage.human_attribute_name(:remaining_hours) }, ->(parent) { parent.remaining_hours }, DURATION),
        attribute(:parent_finish_date, -> { WorkPackage.human_attribute_name(:due_date) }, ->(parent) { parent.due_date }, DATE),
        attribute(:parent_priority, -> { WorkPackage.human_attribute_name(:priority) }, ->(parent) { parent.priority }),
        attribute(:parent_subject, -> { WorkPackage.human_attribute_name(:subject) }, ->(parent) { parent.subject }),
        attribute(:parent_status, -> { WorkPackage.human_attribute_name(:status) }, ->(parent) { parent.status }),
        attribute(:parent_type, -> { WorkPackage.human_attribute_name(:type) }, ->(parent) { parent.type }),
        attribute(:parent_version, -> { WorkPackage.human_attribute_name(:version) }, ->(parent) { parent.version }),
        attribute(:priority, -> { WorkPackage.human_attribute_name(:priority) }, ->(wp) { wp.priority }),
        attribute(:project_id, -> { Project.human_attribute_name(:id) }, ->(project) { project.id }),
        attribute(:project_active, -> { Project.human_attribute_name(:active) }, ->(project) { project.active? }),
        attribute(:project_name, -> { Project.human_attribute_name(:name) }, ->(project) { project }),
        attribute(:project_status, -> { Project.human_attribute_name(:status_code) }, ->(project) { project.status_code && I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}") }),
        attribute(:project_parent, -> { Project.human_attribute_name(:parent) }, ->(project) { project.parent_id }),
        attribute(:project_public, -> { Project.human_attribute_name(:public) }, ->(project) { project.public? }),
        attribute(:start_date, -> { WorkPackage.human_attribute_name(:start_date) }, ->(wp) { wp.start_date }, DATE),
        attribute(:status, -> { WorkPackage.human_attribute_name(:status) }, ->(wp) { wp.status }),
        attribute(:type, -> { WorkPackage.human_attribute_name(:type) }, ->(wp) { wp.type }),
        attribute(:version, -> { WorkPackage.human_attribute_name(:version) }, ->(wp) { wp.version })
      ].freeze
      # rubocop:enable Layout/LineLength

      def partitioned_tokens_for_type(type)
        enabled_tokens = [
          *BASE_ATTRIBUTE_TOKENS,
          *tokenize(work_package_cfs_for(type)),
          *tokenize(project_cfs, "project_"),
          *tokenize(all_work_package_cfs, "parent_")
        ].to_set

        all_tokens.partition { |token| enabled_tokens.include?(token) }
      end

      private

      def all_tokens
        [
          *BASE_ATTRIBUTE_TOKENS,
          *tokenize(all_work_package_cfs),
          *tokenize(project_cfs, "project_"),
          *tokenize(all_work_package_cfs, "parent_")
        ]
      end

      def default_tokens
        BASE_ATTRIBUTE_TOKENS.each_with_object({ work_package: {}, project: {}, parent: {} }) do |token, obj|
          case token.key.to_s
          when /^project_/
            obj[:project][token.key] = token
          when /^parent_/
            obj[:parent][token.key] = token
          else
            obj[:work_package][token.key] = token
          end
        end
      end

      def prefixed_label(context, attribute_label)
        attribute_context = I18n.t("types.edit.subject_configuration.token.context.#{context}")
        I18n.t("types.edit.subject_configuration.token.label_with_context", attribute_context:, attribute_label:)
      end

      def tokenize(custom_field_scope, prefix = nil)
        custom_field_scope.pluck(:name, :id, :field_format, :multi_value).map do |name, id, format, multiple|
          formatter = if multiple
                        ARRAY
                      elsif format == "date"
                        DATE
                      else
                        ->(v) { v.is_a?(Symbol) ? v : STRING_OR_NIL.call(v) }
                      end
          AttributeToken.new(
            :"#{prefix}custom_field_#{id}",
            -> { name },
            ->(context) do
              key = :"custom_field_#{id}"
              return :attribute_not_available unless context.respond_to?(key)

              context.public_send(key)
            end,
            formatter
          )
        end
      end

      def work_package_cfs_for(type)
        all_work_package_cfs.merge(type.custom_fields)
      end

      def all_work_package_cfs
        WorkPackageCustomField.where.not(field_format: %w[text link empty]).order(:name)
      end

      def project_cfs
        ProjectCustomField.where.not(field_format: %w[text link empty]).where(admin_only: false, multi_value: false).order(:name)
      end
    end
  end
end
