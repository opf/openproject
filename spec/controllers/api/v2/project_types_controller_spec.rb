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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::ProjectTypesController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'index.xml' do
    def fetch
      get 'index', :format => 'xml'
    end
    it_should_behave_like "a controller action with unrestricted access"

    describe 'with no project types available' do
      it 'assigns an empty project_types array' do
        get 'index', :format => 'xml'
        assigns(:project_types).should == []
      end

      it 'renders the index builder template' do
        get 'index', :format => 'xml'
        response.should render_template('api/v2/project_types/index', :formats=>["api"])
      end
    end

    describe 'with some project types available' do
      before do
        @created_project_types = [
          FactoryGirl.create(:project_type),
          FactoryGirl.create(:project_type),
          FactoryGirl.create(:project_type)
        ]
      end

      it 'assigns an array with all project types' do
        get 'index', :format => 'xml'
        assigns(:project_types).should == @created_project_types
      end

      it 'renders the index template' do
        get 'index', :format => 'xml'
        response.should render_template('api/v2/project_types/index', :formats=>["api"])
      end
    end
  end

  describe 'show.xml' do
    describe 'with unknown project type' do
      it 'raises ActiveRecord::RecordNotFound errors' do
        lambda do
          get 'show', :id => '1337', :format => 'xml'
        end.should raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'with an available project type' do
      before do
        @available_project_type = FactoryGirl.create(:project_type, :id => '1337')
      end

      def fetch
        get "show", :id => '1337', :format => 'xml'
      end
      it_should_behave_like "a controller action with unrestricted access"


      it 'assigns the available project type' do
        get 'show', :id => '1337', :format => 'xml'
        assigns(:project_type).should == @available_project_type
      end

      it 'renders the show template' do
        get 'show', :id => '1337', :format => 'xml'
        response.should render_template('api/v2/project_types/show', :formats=>["api"])
      end
    end
  end
end
