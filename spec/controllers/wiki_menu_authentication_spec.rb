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

describe WikiMenuItemsController do
  before do
    User.delete_all
    Role.delete_all

    @project = FactoryGirl.create(:project)
    @project.reload # project contains wiki by default


    @params = {}
    @params[:project_id] = @project.id
    page = FactoryGirl.create(:wiki_page, :wiki => @project.wiki)
    @params[:id] = page.title
  end

  describe 'w/ valid auth' do
    it 'renders the edit action' do
      admin_user = FactoryGirl.create(:admin)

      User.stub(:current).and_return admin_user
      permission_role = FactoryGirl.create(:role, :name => "accessgranted", :permissions => [:manage_wiki_menu])
      member = FactoryGirl.create(:member, :principal => admin_user, :user => admin_user, :project => @project, :roles => [permission_role])

      get 'edit', @params

      response.should be_success
    end
  end

  describe 'w/o valid auth' do

    it 'be forbidden' do
      User.stub(:current).and_return FactoryGirl.create(:user)

      get 'edit', @params

      response.status.should == 403 # forbidden
    end
  end
end
