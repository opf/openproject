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

require "spec_helper"

RSpec.describe "Calendars", :skip_csrf, type: :rails_request do
  let(:project_a) { create(:project) }
  let(:project_b) { create(:project) }
  let(:attacker) do
    create(:user,
           member_with_permissions: {
             project_a => %i[view_work_packages view_calendar manage_calendars],
             project_b => %i[view_work_packages view_calendar]
           })
  end
  let(:other_user) { create(:user) }
  let!(:target_query) { create(:query, project: project_b, user: other_user, public: true) }

  before do
    create(:view_work_packages_calendar, query: target_query)
    login_as(attacker)
  end

  describe "DELETE /projects/:project_id/calendars/:id" do
    it "does not delete calendars from another project" do
      delete project_calendar_path(project_a, target_query)

      expect(response).to have_http_status(:not_found)
      expect(Query.exists?(target_query.id)).to be(true)
    end
  end
end
