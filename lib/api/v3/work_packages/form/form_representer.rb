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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      module Form
        class FormRepresenter < Roar::Decorator
          include Roar::JSON::HAL
          include Roar::Hypermedia
          include API::Utilities::UrlHelper
          include OpenProject::TextFormatting

          self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

          def initialize(model, options = {})
            @current_user = options[:current_user]

            super(model)
          end

          property :_type, exec_context: :decorator, writeable: false

          link :self do
            {
              href: "#{root_path}api/v3/work_packages/#{represented.id}/form",
            }
          end

          link :validate do
            {
              href: "#{root_path}api/v3/work_packages/#{represented.id}/form",
              method: :post
            }
          end

          link :previewMarkup do
            {
              href: "#{root_path}api/v3/render/textile?"\
                    "#{root_path}api/v3/work_packages/#{represented.id}",
              method: :post
            }
          end

          link :commit do
            {
              href: "#{root_path}api/v3/work_packages/#{represented.id}",
              method: :patch
            } if @current_user.allowed_to?(:edit_work_packages, represented.project) &&
                 # Calling valid? on represented empties the list of errors
                 # also removing errors from other sources (like contracts).
                 represented.errors.empty?
          end

          property :payload,
                   embedded: true,
                   decorator: Form::WorkPackagePayloadRepresenter,
                   getter: -> (*) { self }
          property :schema,
                   embedded: true,
                   exec_context: :decorator,
                   getter: -> (*) {
                     Form::WorkPackageSchemaRepresenter.new(represented,
                                                            current_user: @current_user)
                   }
          property :validation_errors, embedded: true, exec_context: :decorator

          def _type
            'Form'
          end

          def validation_errors
            errors = represented.errors

            errors.keys.each_with_object({}) do |key, hash|
              error = ::API::Errors::Validation.new(errors.full_message(key, errors[key]))
              hash[key] = ::API::V3::Errors::ErrorRepresenter.new(error)
            end
          end
        end
      end
    end
  end
end
