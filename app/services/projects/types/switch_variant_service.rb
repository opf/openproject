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

module Projects
  module Types
    # Moves a project from the member of a type family it uses to another one, in either
    # direction: a sibling variant, the shared root, or a variant of the root it uses. The
    # project's work packages are untouched: they store the root either way, so the switch is
    # a change of which configuration the project resolves to, not a retype.
    class SwitchVariantService < BaseService
      def initialize(user:, model:, contract_class: SwitchVariantContract)
        super
      end

      private

      # The pair is what the contract judges, and it only arrives with the call, so the
      # options cannot be handed over at construction time like a contract class can.
      def before_perform(service_call)
        self.contract_options = params.slice(:source, :target)

        service_call
      end

      def persist(service_call)
        switch(params[:target])

        service_call
      end

      def switch(target)
        current_project_type = model.project_types.find_by!(type_id: target.root_id)

        if target.variant?
          current_project_type.update!(variant: target)
        else
          current_project_type.update!(variant: nil)
        end

        enable_work_package_custom_fields(target)
      end
    end
  end
end
