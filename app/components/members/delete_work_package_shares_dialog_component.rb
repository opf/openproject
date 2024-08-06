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

module Members
  class DeleteWorkPackageSharesDialogComponent < ::ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
    options :row

    delegate :table,
             :shared_work_packages_count,
             :all_shared_work_packages_count,
             :shared_work_packages_link,
             :all_shared_work_packages_link,
             :administration_settings_link,
             :may_manage_user?,
             to: :row

    delegate :shared_role_id,
             :shared_role_name,
             to: :table

    delegate :principal,
             :other_shared_work_packages_count?,
             :direct_shared_work_packages_count?,
             :inherited_shared_work_packages_count?,
             to: :model

    def paragraph(&) = render(Primer::Beta::Text.new(tag: "p"), &)
    def button(**, &) = render(Primer::Beta::Button.new(**), &)

    def cancel_button = button(data: { close_dialog_id: id }) { t(:button_cancel) }

    def scoped_t(key, **)
      t(key, scope: "members.delete_work_package_shares_dialog", **)
    end

    def id
      "principal-#{principal.id}-delete-work-package-shares-dialog"
    end

    def delete_url(work_package_shares_role_id: nil)
      url_for(
        controller: "/members",
        action: "destroy_by_principal",
        project_id: row.project,
        principal_id: row.principal,
        work_package_shares_role_id:
      )
    end
  end
end
