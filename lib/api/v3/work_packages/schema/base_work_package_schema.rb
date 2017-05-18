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

module API
  module V3
    module WorkPackages
      module Schema
        class BaseWorkPackageSchema
          class << self
            @@writable_properties = [
              :subject,
              :description,
              :estimated_time,
              :assignee,
              :responsible,
              :type,
              :status,
              :category,
              :version,
              :priority,
              :percentage_done,
              :estimated_time,
              :start_date,
              :due_date,
              :date,
              :project
            ]

            def writable_properties
              @@writable_properties.dup.freeze
            end

            def register_writable_property(property)
              @@writable_properties << property.to_sym
            end
          end

          def project
            nil
          end

          def type
            nil
          end

          def assignable_values(_property, _current_user)
            nil
          end

          def assignable_custom_field_values(_custom_field)
            nil
          end

          def available_custom_fields
            []
          end

          def writable?(property)
            case property
            when :percentage_done
              percentage_done_writable?
            else
              self.class.writable_properties.include? property
            end
          end

          def milestone?
            false
          end

          ##
          # Return of a map of attribute => group name
          def attribute_group_map(key)
            return nil if type.nil?
            @attribute_group_map ||= begin
              attribute_groups.each_with_object({}) do |(group, attributes), hash|
                attributes.each { |prop| hash[prop] = group }
              end
            end

            @attribute_group_map[key]
          end

          def attribute_groups
            return nil if type.nil?

            @attribute_groups ||= begin
              type.attribute_groups.map do |group|
                group[1].map! do |prop|
                  if type.passes_attribute_constraint?(prop, project: project)
                    convert_property(prop)
                  end
                end

                group[1].compact!
                group[0] = type.translated_attribute_group(group[0])
                group
              end
            end

            @attribute_groups
          end

          private

          def convert_property(prop)
            ::API::Utilities::PropertyNameConverter.from_ar_name(prop)
          end

          def percentage_done_writable?
            Setting.work_package_done_ratio == 'field'
          end
        end
      end
    end
  end
end
