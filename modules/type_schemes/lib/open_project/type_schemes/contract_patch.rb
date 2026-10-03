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

# frozen_string_literal: true

module OpenProject::TypeSchemes
  module ContractPatch
    def assignable_types
      scope = super
      allowed = ::TypeSchemes::Resolver.allowed_types(model.project, scope)
      return scope if allowed.equal?(scope)

      allowed = allowed.to_a
      current = model.type_id_was && scope.find { |t| t.id == model.type_id_was }
      allowed << current if current && allowed.exclude?(current)
      allowed
    end

    private

    def validate_enabled_type
      super
      return unless model.project && type_context_changed?
      return if ::TypeSchemes::Resolver.for_project(model.project).nil?

      errors.add :type_id, :not_in_scheme unless assignable_types.map(&:id).include?(model.type_id)
    end
  end
end
