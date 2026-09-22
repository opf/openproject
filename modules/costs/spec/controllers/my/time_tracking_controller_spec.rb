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

require_relative "../../spec_helper"

RSpec.describe My::TimeTrackingController do
  let(:user) { create(:user) }

  before do
    login_as user
  end

  describe "GET /my/time-tracking" do
    context "when requesting on a non mobile device" do
      before do
        allow(controller).to receive(:mobile?).and_return(false)
      end

      context "and tracking start and end times is enabled" do
        before do
          allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(true)
        end

        it "renders the work week view" do
          get :index
          expect(assigns(:mode)).to eq(:workweek)
          expect(assigns(:view_mode)).to eq(:calendar)
        end
      end

      context "and tracking start and end times is disabled" do
        before do
          allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(false)
        end

        it "renders the work week list view" do
          get :index
          expect(assigns(:mode)).to eq(:workweek)
          expect(assigns(:view_mode)).to eq(:list)
        end
      end
    end

    context "when requesting on a mobile device" do
      before do
        allow(controller).to receive(:mobile?).and_return(true)
      end

      context "and tracking start and end times is enabled" do
        before do
          allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(true)
        end

        it "renders the day calendar view" do
          get :index
          expect(assigns(:mode)).to eq(:day)
          expect(assigns(:view_mode)).to eq(:calendar)
        end
      end

      context "and tracking start and end times is disabled" do
        before do
          allow(TimeEntry).to receive(:can_track_start_and_end_time?).and_return(false)
        end

        it "renders the day list view" do
          get :index
          expect(assigns(:mode)).to eq(:day)
          expect(assigns(:view_mode)).to eq(:list)
        end
      end
    end

    context "when requesting the chart view mode" do
      it "renders the chart view" do
        get :index, params: { mode: :week, view_mode: :chart }

        expect(assigns(:view_mode)).to eq(:chart)
        expect(response).to be_successful
      end
    end
  end

  describe "GET /my/time-tracking/day" do
    it "without a date param it uses the current date" do
      get :index, params: { mode: :day }
      expect(assigns(:date)).to eq(Date.current)
    end

    it "with a date param it uses the given date" do
      get :index, params: { mode: :day, date: "2023-12-31" }
      expect(assigns(:date)).to eq(Date.parse("2023-12-31"))
    end

    it "with an invalid date param it uses the current date" do
      get :index, params: { mode: :day, date: "invalid-date" }
      expect(assigns(:date)).to eq(Date.current)
    end
  end

  describe "GET /my/time-tracking/week" do
    it "without a date param it uses the current day" do
      get :index, params: { mode: :week }
      expect(assigns(:date)).to eq(Date.current)
    end

    it "with a date param it uses the given date" do
      get :index, params: { mode: :week, date: "2023-12-31" }
      expect(assigns(:date)).to eq(Date.parse("2023-12-31"))
    end

    it "with an invalid date param it uses the current day" do
      get :index, params: { mode: :week, date: "invalid-date" }
      expect(assigns(:date)).to eq(Date.current)
    end
  end

  describe "GET /my/time-tracking/month" do
    it "without a date param it uses the current day" do
      get :index, params: { mode: :month }
      expect(assigns(:date)).to eq(Date.current)
    end

    it "with a date param it uses the given date" do
      get :index, params: { mode: :month, date: "2023-12-31" }
      expect(assigns(:date)).to eq(Date.parse("2023-12-31"))
    end

    it "with an invalid date param it uses the current day" do
      get :index, params: { mode: :month, date: "invalid-date" }
      expect(assigns(:date)).to eq(Date.current)
    end
  end
end
