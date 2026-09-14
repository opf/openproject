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

module Roles
  class DeleteDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    TEST_SELECTOR = "op-roles--delete-dialog"

    alias_method :role, :model

    def form_arguments
      { action: role_path(role), method: :delete }
    end

    def content
      @content ||=
        if role.is_a?(GlobalRole)
          DeleteDialog::GlobalRoleContentComponent.new(role)
        else
          DeleteDialog::ProjectRoleContentComponent.new(role)
        end
    end

    def heading
      if content.in_use?
        content.heading
      else
        t("roles.delete_dialog.heading_unused", name: role.name)
      end
    end
  end
end
