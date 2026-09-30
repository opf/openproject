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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "My time menu",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking costs]) }

  let(:request) { get "/" }

  subject do
    request
    response
  end

  context "when user has no permission in any project" do
    current_user { build_stubbed(:user) }

    it "shows a pagination" do
      expect(subject).to have_http_status(:ok)
      expect(page).to have_no_text "My time tracking"
    end
  end

  context "when user has permission to log_own_time" do
    current_user { create(:user, member_with_permissions: { project => %i[log_own_time] }) }

    it "shows a pagination" do
      expect(subject).to have_http_status(:ok)
      expect(page).to have_text "My time tracking"
    end
  end

  context "when user has permission to log_time" do
    current_user { create(:user, member_with_permissions: { project => %i[log_time] }) }

    it "shows a pagination" do
      expect(subject).to have_http_status(:ok)
      expect(page).to have_text "My time tracking"
    end
  end
end
