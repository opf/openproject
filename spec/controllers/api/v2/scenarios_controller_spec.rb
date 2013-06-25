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

describe Api::V2::ScenariosController do
  describe 'index.xml' do
    describe 'w/o a given project' do
      it 'renders a 404 Not Found page' do
        get 'index', :format => 'xml'

        response.response_code.should == 404
      end
    end

    describe 'w/ an unknown project' do
      it 'renders a 404 Not Found page' do
        get 'index', :project_id => '4711', :format => 'xml'

        response.response_code.should == 404
      end
    end

    describe 'w/ a known project' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

      describe 'w/o any scenarios within the project' do
        it 'assigns an empty scenarios array' do
          get 'index', :project_id => project.id, :format => 'xml'
          assigns(:scenarios).should == []
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.id, :format => 'xml'
          response.should render_template('scenarios/index', :formats => ["api"])
        end
      end

      describe 'w/ 3 scenarios within the project' do
        before do
          @created_scenarios = [
            FactoryGirl.create(:scenario, :project_id => project.id),
            FactoryGirl.create(:scenario, :project_id => project.id),
            FactoryGirl.create(:scenario, :project_id => project.id)
          ]
        end

        it 'assigns a scenarios array containing all three elements' do
          get 'index', :project_id => project.id, :format => 'xml'
          assigns(:scenarios).should =~ @created_scenarios
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.id, :format => 'xml'
          response.should render_template('scenarios/index', :formats => ["api"])
        end
      end
    end

    describe 'access control' do
      describe 'with a private project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project',
                                                 :is_public  => false) }

        def fetch
          get 'index', :project_id => project.id, :format => 'xml'
        end
        it_should_behave_like "a controller action which needs project permissions"
      end

      describe 'with a public project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project',
                                                 :is_public  => true) }

        def fetch
          get 'index', :project_id => project.id, :format => 'xml'
        end
        it_should_behave_like "a controller action with unrestricted access"
      end
    end
  end

  describe 'show.xml' do
    describe 'w/o a valid scenario id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => '4711', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'index', :project_id => '4711', :id => '1337', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        it 'raises ActiveRecord::RecordNotFound errors' do
          lambda do
            get 'show', :project_id => project.id, :id => '1337', :format => 'xml'
          end.should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'w/ a valid scenario id' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:scenario) { FactoryGirl.create(:scenario, :project_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => scenario.id, :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        it 'assigns the scenario' do
          get 'show', :project_id => project.id, :id => scenario.id, :format => 'xml'
          assigns(:scenario).should == scenario
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.id, :id => scenario.id, :format => 'xml'
          response.should render_template('scenarios/index', :formats => ["api"])
        end
      end

      describe 'access control' do
        describe 'with a private project' do
          let(:project) { FactoryGirl.create(:project, :identifier => 'test_project',
                                                   :is_public  => false) }

          def fetch
            get 'index', :project_id => project.id, :id => scenario.id, :format => 'xml'
          end
          it_should_behave_like "a controller action which needs project permissions"
        end

        describe 'with a public project' do
          let(:project) { FactoryGirl.create(:project, :identifier => 'test_project',
                                                   :is_public  => true) }

          def fetch
            get 'index', :project_id => project.id, :id => scenario.id, :format => 'xml'
          end
          it_should_behave_like "a controller action with unrestricted access"
        end
      end
    end
  end

  def project_settings_path(project)
    {:controller => 'projects', :action => 'settings', :tab => 'timelines', :id => project}
  end
end
