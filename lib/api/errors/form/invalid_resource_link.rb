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
  module Errors
    module Form
      class InvalidResourceLink < StandardError
        def initialize(property, expected_resource, actual_resource = :unknown)
          property_localized = I18n.t("attributes.#{property}")
          expected_localized = I18n.t("attributes.#{expected_resource.to_s.singularize}")
          actual_localized = I18n.t("attributes.#{actual_resource.to_s.singularize}")
          message = I18n.t('api_v3.errors.invalid_resource',
                           property: property_localized,
                           expected: expected_localized,
                           actual: actual_localized)

          super(message)
        end
      end
    end
  end
end
