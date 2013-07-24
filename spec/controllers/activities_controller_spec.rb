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

describe ActivitiesController do
  before :each do
    @controller.stub(:set_localization)

    admin = FactoryGirl.create(:admin)
    User.stub(:current).and_return admin

    @params = {}
  end

  describe 'index' do
    describe 'with activated activity module' do
      before do
        @project = FactoryGirl.create(:project, :enabled_module_names => %w[activity wiki])
        @params[:project_id] = @project.id
      end

      it 'renders activity' do
        get 'index', @params
        response.should be_success
        response.should render_template 'index'
      end
    end

    describe 'without activated activity module' do
      before do
        @project = FactoryGirl.create(:project, :enabled_module_names => %w[wiki])
        @params[:project_id] = @project.id
      end

      it 'renders 403' do
        get 'index', @params
        response.status.should == 403
        response.should render_template 'common/error'
      end
    end
  end
end
