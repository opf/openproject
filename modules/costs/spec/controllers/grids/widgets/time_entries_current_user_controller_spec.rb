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

require_relative "../../../spec_helper"

RSpec.describe Grids::Widgets::TimeEntriesCurrentUserController do
  let(:user) { create(:user) }

  before do
    login_as user
  end

  def rendered_mode
    modes = []

    allow(Grids::Widgets::TimeEntriesCurrentUser)
      .to receive(:new).and_wrap_original do |original, **args|
        modes << args[:mode]
        original.call(**args)
      end

    yield

    modes.last
  end

  describe "the mode the widget shows" do
    it "defaults to the work week" do
      expect(rendered_mode { get :show }).to eq(:workweek)
    end

    it "follows the mode the user last settled on" do
      user.pref.update(my_work_mode: "week")

      expect(rendered_mode { get :show }).to eq(:week)
    end

    it "follows a remembered month" do
      user.pref.update(my_work_mode: "month")

      expect(rendered_mode { get :show }).to eq(:month)
    end

    it "falls back to the work week for a mode it cannot show" do
      user.pref.update(my_work_mode: "decade")

      expect(rendered_mode { get :show }).to eq(:workweek)
    end

    it "prefers the requested mode over the remembered one" do
      user.pref.update(my_work_mode: "week")

      expect(rendered_mode { get :show, params: { mode: "day" } }).to eq(:day)
    end
  end

  describe "remembering the mode" do
    it "keeps the mode the widget was stepped to" do
      get :show, params: { mode: "week" }

      expect(user.reload.pref.my_work_mode).to eq("week")
    end

    it "leaves the remembered mode alone when none is requested" do
      user.pref.update(my_work_mode: "day")

      get :show

      expect(user.reload.pref.my_work_mode).to eq("day")
    end
  end
end
