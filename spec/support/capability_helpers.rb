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

module CapabilityHelpers
  def global_admin_capabilities(principal)
    admin_contract_actions { it[:global] }
      .map { [it, principal.id, nil] }
  end

  def project_admin_capabilities(principal, project)
    admin_contract_actions { !it[:global] && module_enabled?(project, it[:module_name]) }
      .map { [it, principal.id, project.id] }
  end

  private

  def admin_contract_actions(&)
    OpenProject::AccessControl
      .contract_actions_map
      .values
      .select { it[:grant_to_admin] }
      .select(&)
      .flat_map { |permission| permission[:actions].to_a }
      .flat_map { |namespace, actions| actions.map { capability_action(namespace, it) } }
      .uniq
  end

  def capability_action(namespace, action)
    "#{API::Utilities::PropertyNameConverter.from_ar_name(namespace.to_s.singularize).pluralize.underscore}/#{action}"
  end

  def module_enabled?(project, module_name)
    module_name.blank? || project.enabled_module_names.include?(module_name.to_s)
  end
end
