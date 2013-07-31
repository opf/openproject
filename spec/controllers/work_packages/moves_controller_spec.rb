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

describe WorkPackages::MovesController do

  let(:project) { FactoryGirl.create(:project, :is_public => false) }
  let(:work_package) { FactoryGirl.create(:planning_element, :project_id => project.id) }

  let(:current_user) { FactoryGirl.create(:user) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'new.html' do
    become_admin

    describe 'w/o a valid planning element id' do

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 404 page' do
          get 'new', :id => '1337'

          response.response_code.should === 404
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it 'raises ActiveRecord::RecordNotFound errors' do
          get 'new', :id => '1337'

          response.response_code.should === 404
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'new', :work_package_id => work_package.id

          response.response_code.should == 403
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_move_work_package_permissions

        before do
          get 'new', :work_package_id => work_package.id
        end

        it 'renders the new builder template' do
          response.should render_template('work_packages/moves/new', :formats => ["html"], :layout => :base)
        end
      end
    end
  end
end
