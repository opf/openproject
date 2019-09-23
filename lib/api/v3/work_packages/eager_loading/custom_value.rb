#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module API
  module V3
    module WorkPackages
      module EagerLoading
        class CustomValue < Base
          def apply(work_package)
            load_custom_values(work_package)
            load_custom_values_values(work_package)
            load_available_custom_fields(work_package)
          end

          def self.module
            CustomFieldAccessor
          end

          private

          def load_custom_values(work_package)
            work_package.association(:custom_values).loaded!
            work_package.association(:custom_values).target = custom_values(work_package.id)
          end

          def load_custom_values_values(work_package)
            work_package.custom_values.each do |cv|
              next unless cv.custom_field && cv.value.present?

              loaded_value = case cv.custom_field.field_format
                             when 'user'
                               user_values(cv.value)
                             when 'version'
                               version_values(cv.value)
                             when 'list'
                               list_values(cv.value)
                             end

              cv.value = loaded_value if loaded_value
            end
          end

          def load_available_custom_fields(work_package)
            work_package.available_custom_fields = custom_fields_of(work_package).to_a
          end

          def grouped_custom_values
            @grouped_custom_values ||= begin
              custom_values = ::CustomValue
                              .where(customized_type: 'WorkPackage', customized_id: work_packages.map(&:id))
                              .group_by(&:customized_id)

              custom_values.each_value do |values|
                values.each do |value|
                  value.custom_field = custom_field(value.custom_field_id)
                end
              end

              custom_values
            end
          end

          def custom_values(id)
            grouped_custom_values[id] || []
          end

          def user_values(id)
            @user_values ||= eager_load_values 'user', User.includes(:preference)

            @user_values[id.to_i]
          end

          def version_values(id)
            @version_values ||= eager_load_values 'version', Version

            @version_values[id.to_i]
          end

          def list_values(id)
            @list_values ||= eager_load_values 'list', CustomOption

            @list_values[id.to_i]
          end

          def eager_load_values(field_format, scope)
            cvs = custom_values_of(field_format)

            ids_of_values = cvs.map(&:value).select { |v| v =~ /\A\d+\z/ }

            return {} if ids_of_values.empty?

            scope
              .where(id: ids_of_values)
              .map { |v| [v.id, v] }
              .to_h
          end

          def custom_values_of(field_format)
            grouped_custom_values
              .values
              .flatten
              .select { |cv| cv.custom_field && cv.custom_field.field_format == field_format && cv.value.present? }
          end

          def usages
            @usages ||= begin
              ActiveRecord::Base
                .connection
                .select_all(configured_fields_sql)
                .to_a
                .uniq
            end
          end

          def custom_field(id)
            @loaded_custom_fields_by_id ||= begin
              WorkPackageCustomField
                .where(id: usages.map { |u| u['custom_field_id'] }.uniq)
                .map { |cf| [cf.id, cf] }
                .to_h
            end

            @loaded_custom_fields_by_id[id]
          end

          def usage_map
            @usage_map ||= begin
              usages.inject(usage_hash) do |hash, by|
                cf = custom_field(by['custom_field_id'])
                target_project_id = by['project_id']

                # If the project_id is NOT nil, and the custom_field is `is_for_all`
                # Ensure that it gets added to hash[nil] (Regression #28435)
                if by['project_id'].present? && cf.is_for_all
                  target_project_id = nil
                end

                hash[target_project_id][by['type_id']] << cf

                hash
              end
            end
          end

          def custom_fields_of(work_package)
            usage_map[work_package.project_id][work_package.type_id] +
              usage_map[nil][work_package.type_id]
          end

          def configured_fields_sql
            WorkPackageCustomField
              .left_joins(:projects, :types)
              .where(projects: { id: work_packages.map(&:project_id).uniq },
                     types: { id: work_packages.map(&:type_id).uniq })
              .or(WorkPackageCustomField
                    .left_joins(:projects, :types)
                    .references(:projects, :types)
                    .where(is_for_all: true))
              .select('projects.id project_id',
                      'types.id type_id',
                      'custom_fields.id custom_field_id')
              .to_sql
          end

          def usage_hash
            Hash.new do |by_project_hash, project_id|
              by_project_hash[project_id] = Hash.new do |by_type_hash, type_id|
                # Use a set to ensure CFs are only available once
                by_type_hash[type_id] = Set.new
              end
            end
          end
        end

        module CustomFieldAccessor
          extend ActiveSupport::Concern

          # Because of the ruby method lookup,
          # wrapping the work_package here and define the
          # available_custom_fields methods on the wrapper does not suffice.
          # We thus extend each work package.
          included do
            def initialize(work_package)
              super
              work_package.extend(CustomFieldAccessorPatch)
            end
          end
        end

        module CustomFieldAccessorPatch
          def available_custom_fields
            @available_custom_fields
          end

          def available_custom_fields=(fields)
            @available_custom_fields = fields
          end
        end
      end
    end
  end
end
