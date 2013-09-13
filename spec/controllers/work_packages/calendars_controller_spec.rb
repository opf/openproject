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
  let(:user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role,
                                  permissions: [:view_work_packages]) }
  let(:project) { FactoryGirl.create(:project) }
  let(:member) { FactoryGirl.create(:member,
                                    project: project,
                                    principal: user,
                                    roles: [role]) }
  let(:work_package) { FactoryGirl.create(:work_package,
                                          project: project) }


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

    context :project do
      before do
        member
        work_package

        User.stub(:current).and_return(user)

        get :index, project_id: project.id
      end

      it_behaves_like "calendar#index"
    end
  end
end
