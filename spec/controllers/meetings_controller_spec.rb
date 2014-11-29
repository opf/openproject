#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe MeetingsController, type: :controller do
  before(:each) do
    @p = mock_model(Project)
    allow(@controller).to receive(:authorize)
    allow(@controller).to receive(:check_if_login_required)
  end

  describe "GET" do
    describe "index" do
      before(:each) do
        allow(Project).to receive(:find).and_return(@p)
        @ms = [mock_model(Meeting), mock_model(Meeting), mock_model(Meeting)]
        allow(@ms).to receive(:from_tomorrow).and_return(@ms)
        allow(@p).to receive(:meetings).and_return(@ms)
        [:with_users_by_date, :page, :per_page].each do |meth|
          expect(@ms).to receive(meth).and_return(@ms)
        end
        @grouped = double('grouped')
        expect(Meeting).to receive(:group_by_time).with(@ms).and_return(@grouped)
      end
      describe "html" do
        before(:each) do
          get "index", project_id: @p.id
        end
        it {expect(response).to be_success}
        it {expect(assigns(:meetings_by_start_year_month_date)).to eql @grouped }
      end
    end

    describe "show" do
      before(:each) do
        @m = mock_model(Meeting)
        allow(Meeting).to receive(:find).and_return(@m)
        allow(@m).to receive(:project).and_return(@p)
        allow(allow(@m).to receive(:agenda)).to receive(:present?).and_return(false)
      end
      describe "html" do
        before(:each) do
          get "show", id: @m.id
        end
        it {expect(response).to be_success}
      end
    end

    describe "new" do
      before(:each) do
        allow(Project).to receive(:find).and_return(@p)
        @m = mock_model(Meeting)
        allow(@m).to receive(:project=)
        allow(@m).to receive(:author=)
        allow(Meeting).to receive(:new).and_return(@m)
      end
      describe "html" do
        before(:each) do
          get "new", project_id: @p.id
        end
        it {expect(response).to be_success}
        it {expect(assigns(:meeting)).to eql @m}
      end
    end

    describe "edit" do
      before(:each) do
        @m = mock_model(Meeting)
        allow(Meeting).to receive(:find).and_return(@m)
        allow(@m).to receive(:project).and_return(@p)
      end
      describe "html" do
        before(:each) do
          get "edit", id: @m.id
        end
        it {expect(response).to be_success}
        it {expect(assigns(:meeting)).to eql @m}
      end
    end
  end
end
