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

RSpec.describe "Settings" do
  let(:admin) { create(:admin) }

  describe "subsection" do
    before do
      login_as(admin)

      visit "/admin/settings/api"
    end

    shared_examples "it can be visited" do
      let(:section) { raise "define me" }

      before do
        visit "/admin/settings/#{section}"
      end

      it "can be visited" do
        expect(page).to have_content(/#{section}/i)
      end
    end

    describe "general" do
      it_behaves_like "it can be visited" do
        let(:section) { "general" }
      end
    end

    describe "API (regression #34938)" do
      it_behaves_like "it can be visited" do
        let(:section) { "api" }
      end
    end
  end
end
