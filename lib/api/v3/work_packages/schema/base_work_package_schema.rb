#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

          private

          def percentage_done_writable?
            Setting.work_package_done_ratio == 'field'
          end
        end
      end
    end
  end
end
