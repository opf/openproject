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

RSpec.describe "Date picker focused field", type: :rails_request do
  let(:project) { create(:project) }
  let!(:work_package) do
    create(:work_package, project:, start_date: nil, due_date: Date.current, schedule_manually: true)
  end

  let(:viewer) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  current_user { viewer }

  subject(:request) do
    get work_package_date_picker_path(work_package, focused_field:)
  end

  context "when focusing a method name instead of a date field" do
    let(:focused_field) { "destroy" }

    it "does not call the method on the work package" do
      request

      expect(WorkPackage).to exist(work_package.id)
    end
  end

  context "when focusing a date field" do
    let(:focused_field) { "due_date" }

    it "renders the date picker" do
      request

      expect(response).to have_http_status(:ok)
    end
  end
end
