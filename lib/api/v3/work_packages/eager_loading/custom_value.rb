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

module API
  module V3
    module WorkPackages
      module EagerLoading
        class CustomValue < Base
          def initialize(work_packages, **options)
            super

            WorkPackage.preload_available_custom_fields(work_packages)
          end

          def apply(work_package)
            load_custom_values(work_package)
            load_custom_values_values(work_package)
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
                             when "user"
                               user_values(cv.value)
                             when "version"
                               version_values(cv.value)
                             when "list"
                               list_values(cv.value)
                             end

              cv.value = loaded_value if loaded_value
            end
          end

          def grouped_custom_values
            @grouped_custom_values ||= begin
              custom_values = ::CustomValue
                              .where(customized_type: "WorkPackage", customized_id: work_packages.map(&:id))
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
            @user_values ||= eager_load_values "user", User.includes(:preference)

            @user_values[id.to_i]
          end

          def version_values(id)
            @version_values ||= eager_load_values "version", Version

            @version_values[id.to_i]
          end

          def list_values(id)
            @list_values ||= eager_load_values "list", CustomOption

            @list_values[id.to_i]
          end

          def eager_load_values(field_format, scope)
            cvs = custom_values_of(field_format)

            ids_of_values = cvs.map(&:value).grep(/\A\d+\z/)

            return {} if ids_of_values.empty?

            scope
              .where(id: ids_of_values)
              .index_by(&:id)
          end

          def custom_values_of(field_format)
            grouped_custom_values
              .values
              .flatten
              .select { |cv| cv.custom_field && cv.custom_field.field_format == field_format && cv.value.present? }
          end

          def custom_field(id)
            @loaded_custom_fields_by_id ||= work_packages.map(&:available_custom_fields).flatten.uniq.index_by(&:id)

            @loaded_custom_fields_by_id[id]
          end
        end
      end
    end
  end
end
