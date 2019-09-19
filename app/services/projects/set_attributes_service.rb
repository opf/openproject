#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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

module Projects
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_default_attributes(attributes)
      attribute_keys = attributes.keys.map(&:to_s)

      set_default_identifier(attribute_keys.include?('identifier'))
      set_default_is_public(attribute_keys.include?('is_public'))
      set_default_module_names(attribute_keys.include?('enabled_module_names'))
      set_default_types(attribute_keys.include?('types') || attribute_keys.include?('type_ids'))
    end

    def set_default_identifier(provided)
      if !provided && Setting.sequential_project_identifiers?
        model.identifier = Project.next_identifier
      end
    end

    def set_default_is_public(provided)
      model.is_public = Setting.default_projects_public? unless provided
    end

    def set_default_module_names(provided)
      model.enabled_module_names = Setting.default_projects_modules if !provided && model.enabled_module_names.empty?
    end

    def set_default_types(provided)
      model.types = ::Type.default if !provided && model.types.empty?
    end
  end
end
