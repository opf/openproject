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
      class FormRepresenter < ::API::Decorators::Single
        property :payload,
                 embedded: true,
                 decorator: -> (represented, *) {
                   WorkPackagePayloadRepresenter.create_class(represented)
                 },
                 getter: -> (*) { self }
        property :schema,
                 embedded: true,
                 exec_context: :decorator,
                 getter: -> (*) {
                   schema = Schema::WorkPackageSchema.new(work_package: represented)
                   Schema::WorkPackageSchemaRepresenter.create(schema,
                                                               form_embedded: true,
                                                               current_user: current_user)
                 }
        property :validation_errors, embedded: true, exec_context: :decorator

        def _type
          'Form'
        end

        def validation_errors
          ::API::Errors::Validation.create(represented.errors.dup).inject({}) do |h, (k, v)|
            h[k] = ::API::V3::Errors::ErrorRepresenter.new(v)
            h
          end
        end
      end
    end
  end
end
