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

require File.expand_path('../../spec_helper', __FILE__)

describe Timelines::TimelinesProjectAssociationsController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

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

      def fetch
        get 'index', :project_id => project.id, :format => 'xml'
      end
      let(:permission) { :view_project_associations }

      it_should_behave_like "a controller action which needs project permissions"

      describe 'w/ the current user being a member' do
        describe 'w/o any project_associations within the project' do
          it 'assigns an empty project_associations array' do
            get 'index', :project_id => project.id, :format => 'xml'
            assigns(:project_associations).should == []
          end

          it 'renders the index builder template' do
            get 'index', :project_id => project.id, :format => 'xml'
            response.should render_template('timelines/timelines_project_associations/index', :formats => ["api"])
          end
        end

        describe 'w/ 3 project_associations within the project' do
          before do
            @created_project_associations = [
              FactoryGirl.create(:timelines_project_association, :project_a_id => project.id,
                                                             :project_b_id => FactoryGirl.create(:public_project).id),
              FactoryGirl.create(:timelines_project_association, :project_a_id => project.id,
                                                             :project_b_id => FactoryGirl.create(:public_project).id),
              FactoryGirl.create(:timelines_project_association, :project_b_id => project.id,
                                                             :project_a_id => FactoryGirl.create(:public_project).id)
            ]
          end

          it 'assigns a project_associations array containing all three elements' do
            get 'index', :project_id => project.id, :format => 'xml'
            assigns(:project_associations).should == @created_project_associations
          end

          it 'renders the index builder template' do
            get 'index', :project_id => project.id, :format => 'xml'
            response.should render_template('timelines/timelines_project_associations/index', :formats => ["api"])
          end
        end
      end
    end
  end

  describe 'index.html' do
    let(:project) { FactoryGirl.create(:project, :is_public => false) }
    def fetch
      get 'index', :project_id => project.identifier
    end
    let(:permission) { :view_project_associations }

    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'new.html' do
    let(:project) { FactoryGirl.create(:project, :is_public => false) }
    def fetch
      get 'new', :project_id => project.identifier
    end
    let(:permission) { :edit_project_associations }

    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'create.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:project_b) { FactoryGirl.create(:project, :is_public => true) }
    def fetch
      post 'create', :project_id => project.identifier,
                     :project_association => {},
                     :project_association_select => {:project_b_id => project_b.id}
    end
    let(:permission) { :edit_project_associations }
    def expect_redirect_to
      Regexp.new(timelines_project_project_associations_path(project))
    end

    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'show.xml' do
    describe 'w/o a valid project_association id' do
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

        describe 'w/ the current user being a member' do
          it 'raises ActiveRecord::RecordNotFound errors' do
            lambda do
              get 'show', :project_id => project.id, :id => '1337', :format => 'xml'
            end.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid project_association id' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:project_association) { FactoryGirl.create(:timelines_project_association, :project_a_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => project_association.id, :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        def fetch
          get 'show', :project_id => project.id, :id => project_association.id, :format => 'xml'
        end
        let(:permission) { :view_project_associations }

        it_should_behave_like "a controller action which needs project permissions"

        describe 'w/ the current user being a member' do
          it 'assigns the project_association' do
            get 'show', :project_id => project.id, :id => project_association.id, :format => 'xml'
            assigns(:project_association).should == project_association
          end

          it 'renders the index builder template' do
            get 'index', :project_id => project.id, :id => project_association.id, :format => 'xml'
            response.should render_template('timelines/timelines_project_associations/index', :formats => ["api"])
          end
        end
      end
    end
  end

  describe 'edit.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:project_b) { FactoryGirl.create(:project, :is_public => true) }
    let(:project_association) { FactoryGirl.create(:timelines_project_association,
                                               :project_a_id => project.id,
                                               :project_b_id => project_b.id) }
    def fetch
      get 'edit', :project_id => project.identifier,
                  :id         => project_association.id
    end
    let(:permission) { :edit_project_associations }

    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'update.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:project_b) { FactoryGirl.create(:project, :is_public => true) }
    let(:project_association) { FactoryGirl.create(:timelines_project_association,
                                               :project_a_id => project.id,
                                               :project_b_id => project_b.id) }
    def fetch
      post 'update', :project_id => project.identifier,
                     :id         => project_association.id,
                     :project_association => {}
    end
    let(:permission) { :edit_project_associations }
    def expect_redirect_to
      timelines_project_project_associations_path(project)
    end

    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'confirm_destroy.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:project_b) { FactoryGirl.create(:project, :is_public => true) }
    let(:project_association) { FactoryGirl.create(:timelines_project_association,
                                               :project_a_id => project.id,
                                               :project_b_id => project_b.id) }
    def fetch
      get 'confirm_destroy', :project_id => project.identifier,
                             :id         => project_association.id,
                             :project_association => {}
    end
    let(:permission) { :delete_project_associations }

    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'destroy.html' do
    let(:project)   { FactoryGirl.create(:project, :is_public => false) }
    let(:project_b) { FactoryGirl.create(:project, :is_public => true) }
    let(:project_association) { FactoryGirl.create(:timelines_project_association,
                                               :project_a_id => project.id,
                                               :project_b_id => project_b.id) }
    def fetch
      post 'destroy', :project_id => project.identifier,
                      :id         => project_association.id
    end
    let(:permission) { :delete_project_associations }
    def expect_redirect_to
      timelines_project_project_associations_path(project)
    end

    it_should_behave_like "a controller action which needs project permissions"
  end
end
