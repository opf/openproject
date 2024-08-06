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

require "spec_helper"

RSpec.describe "layouts/admin" do
  shared_let(:admin) { create(:admin) }

  include Redmine::MenuManager::MenuHelper
  helper Redmine::MenuManager::MenuHelper

  before do
    without_partial_double_verification do
      allow(view).to receive(:default_breadcrumb)

      parent_menu_item = Object.new
      allow(parent_menu_item).to receive(:name).and_return :root
      allow(view).to receive_messages(current_menu_item: "overview", current_user: admin,
                                      admin_first_level_menu_entry: parent_menu_item)

      allow(controller).to receive(:default_search_scope)
      allow(view).to receive(:render_to_string)
    end

    allow(User).to receive(:current).and_return admin
  end

  # All password-based authentication is to be hidden and disabled if
  # `disable_password_login` is true. This includes LDAP.
  describe "LDAP authentication menu entry" do
    context "with password login enabled" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
        render
      end

      it "is shown" do
        expect(rendered).to have_css("a", text: I18n.t(:label_ldap_auth_source_plural))
      end
    end

    context "with password login disabled" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
        render
      end

      it "is hidden" do
        expect(rendered).to have_no_css("a", text: I18n.t(:label_ldap_auth_source_plural))
      end
    end
  end
end
