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

RSpec.describe "layouts/base" do
  describe "authenticator plugin" do
    include Redmine::MenuManager::MenuHelper
    helper Redmine::MenuManager::MenuHelper
    let(:anonymous) { build_stubbed(:anonymous) }

    before do
      without_partial_double_verification do
        allow(view).to receive(:default_breadcrumb)
        allow(view).to receive_messages(current_menu_item: "overview", current_user: anonymous)
      end
      allow(OpenProject::Plugins::AuthPlugin).to receive(:providers).and_return([provider])
    end

    context "with an authenticator with given icon" do
      let(:provider) do
        { name: "foob_auth", icon: "image.png" }
      end

      before do
        render
      end

      it "adds the CSS to render the icon" do
        expect(rendered).to have_text(/background-image:(?:.*)image.png/)
      end
    end
  end
end
