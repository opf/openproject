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

describe RepositoriesController do
  describe 'commits per author graph' do
    let(:project) { FactoryGirl.create(:project) }
    let(:user) { FactoryGirl.create(:user, :member_in_project => project,
                                            :member_through_role => role) }
    let(:repository) { FactoryGirl.create(:repository, :project => project) }

    before do
      Setting.stub(:enabled_scm).and_return(['Filesystem'])
      repository # ensure repository is created after stubbing the setting
      User.stub(:current).and_return(user)
      get :graph, :id => project.id, :graph => 'commits_per_author'
    end

    context 'requested by an authorized user' do
      let(:role) { FactoryGirl.create(:role, :permissions => [:browse_repository,
                                                              :view_commit_author_statistics]) }

      it 'should be successful' do
        response.should be_success
      end

      it 'should have the right content type' do
        response.content_type.should == 'image/svg+xml'
      end
    end

    context 'requested by an unauthorized user' do
      let(:role) { FactoryGirl.create(:role, :permissions => [:browse_repository]) }

      it 'should return 403' do
        response.code.should == '403'
      end
    end
  end
end
