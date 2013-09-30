#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
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

describe MeetingsController do
  before(:each) do
    @p = mock_model(Project)
    @controller.stub!(:authorize)
    @controller.stub!(:check_if_login_required)
  end

  describe "GET" do
    describe "index" do
      before(:each) do
        Project.stub!(:find).and_return(@p)
        @ms = [mock_model(Meeting), mock_model(Meeting), mock_model(Meeting)]
        @ms.stub!(:from_tomorrow).and_return(@ms)
        @p.stub!(:meetings).and_return(@ms)
        [:with_users_by_date, :page, :per_page].each do |meth|
          @ms.should_receive(meth).and_return(@ms)
        end
        @grouped = double('grouped')
        Meeting.should_receive(:group_by_time).with(@ms).and_return(@grouped)
      end
      describe "html" do
        before(:each) do
          get "index", :project_id => @p.id
        end
        it {response.should be_success}
        it {assigns(:meetings_by_start_year_month_date).should eql @grouped }
      end
    end

    describe "show" do
      before(:each) do
        @m = mock_model(Meeting)
        Meeting.stub!(:find).and_return(@m)
        @m.stub!(:project).and_return(@p)
        @m.stub!(:agenda).stub!(:present?).and_return(false)
      end
      describe "html" do
        before(:each) do
          get "show", :id => @m.id
        end
        it {response.should be_success}
      end
    end

    describe "new" do
      before(:each) do
        Project.stub!(:find).and_return(@p)
        @m = mock_model(Meeting)
        @m.stub!(:project=)
        @m.stub!(:author=)
        Meeting.stub!(:new).and_return(@m)
      end
      describe "html" do
        before(:each) do
          get "new", :project_id => @p.id
        end
        it {response.should be_success}
        it {assigns(:meeting).should eql @m}
      end
    end

    describe "edit" do
      before(:each) do
        @m = mock_model(Meeting)
        Meeting.stub!(:find).and_return(@m)
        @m.stub(:project).and_return(@p)
      end
      describe "html" do
        before(:each) do
          get "edit", :id => @m.id
        end
        it {response.should be_success}
        it {assigns(:meeting).should eql @m}
      end
    end
  end
end
