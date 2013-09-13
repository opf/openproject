#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackages::CalendarsController do
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role,
                                  permissions: [:view_calendar]) }
  let(:user) { FactoryGirl.create(:user,
                                  member_in_project: project,
                                  member_through_role: role) }
  let(:work_package) { FactoryGirl.create(:work_package,
                                          project: project) }

  before { User.stub(:current).and_return(user) }

  describe :index do
    shared_examples_for "calendar#index" do
      subject { response }

      it { should be_success }

      it { should render_template('calendar') }

      context :assigns do
        subject { assigns(:calendar) }

        it { should be_true }
      end
    end

    context "cross-project" do
      before { get :index }

      it_behaves_like "calendar#index"
    end

    context :project do
      before do
        work_package

        get :index, project_id: project.id
      end

      it_behaves_like "calendar#index"
    end

    context "custom query" do
      let (:query) { FactoryGirl.create(:query,
                                        project: nil,
                                        user: user) }

      before { get :index, query_id: query.id }

      it_behaves_like "calendar#index"
    end

    describe "start of week" do
      context "Sunday" do
        before do
          Setting.stub(:start_of_week).and_return(7)

          get :index, month: '1', year: '2010'
        end

        it_behaves_like "calendar#index"

        describe :view do
          render_views

          subject { response }

          it { assert_select("tr td.week-number", content: '53') }

          it { assert_select("tr td.odd", content: '27') }

          it { assert_select("tr td.even", content: '2') }

          it { assert_select("tr td.week-number", content: '1') }

          it { assert_select("tr td.odd", content: '3') }

          it { assert_select("tr td.even", content: '9') }
        end
      end

      context "Monday" do
        before do
          Setting.stub(:start_of_week).and_return(1)

          get :index, month: '1', year: '2010'
        end

        it_behaves_like "calendar#index"

        describe :view do
          render_views

          subject { response }

          it { assert_select("tr td.week-number", content: '53') }

          it { assert_select("tr td.even", content: '28') }

          it { assert_select("tr td.even", content: '3') }

          it { assert_select("tr td.week-number", content: '1') }

          it { assert_select("tr td.even", content: '4') }

          it { assert_select("tr td.even", content: '10') }
        end
      end
    end
  end
end
