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

RSpec.describe AnnouncementsController do
  let(:announcement) { build(:announcement) }

  before do
    allow(controller).to receive(:check_if_login_required)
    expect(controller).to receive(:require_admin)

    allow(Announcement).to receive(:only_one).and_return(announcement)
  end

  describe "#edit" do
    before do
      get :edit
    end

    it do
      expect(assigns(:announcement)).to eql announcement
    end

    it { expect(response).to be_successful }
  end

  describe "#update" do
    before do
      expect(announcement).to receive(:save).and_call_original
      put :update,
          params: {
            announcement: {
              until_date: "2011-01-11",
              text: "announcement!!!",
              active: 1
            }
          }
    end

    it "edits the announcement" do
      expect(response).to redirect_to action: :edit
      expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)
    end
  end
end
