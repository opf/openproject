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

describe WorkPackagesController do
  # ===========================================================
  # Helpers
  def self.become_admin
    let(:current_user) { FactoryGirl.create(:admin) }
  end

  def self.become_non_member(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        current_user.memberships.select {|m| m.project_id == p.id}.each(&:destroy)
      end
    end
  end

  def self.become_member_with_permissions(permissions)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role = FactoryGirl.create(:role, :permissions => permissions)

      member = FactoryGirl.build(:member, :user => current_user, :project => project)
      member.roles = [role]
      member.save!
    end
  end

  def self.become_member_with_view_planning_element_permissions
    become_member_with_permissions [:view_planning_elements, :view_work_packages]
  end

  before do
    User.stub(:current).and_return current_user
  end

  #=======================================================================

  before do
    # disables sending mails
    UserMailer.stub!(:new).and_return(double('mailer').as_null_object)
  end

  let(:planning_element) { FactoryGirl.create(:planning_element, :project_id => project.id) }
  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:stub_planning_element) { FactoryGirl.build_stubbed(:planning_element, :project_id => stub_project.id) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project, :identifier => 'test_project', :is_public => false) }
  let(:stub_issue) { FactoryGirl.build_stubbed(:issue, :project_id => stub_project.id) }
  let(:stub_user) { FactoryGirl.build_stubbed(:user) }

  let(:current_user) { FactoryGirl.create(:user) }

  describe 'show.html' do
    become_admin

    describe 'w/o a valid planning element id' do

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 404 page' do
          get 'show', :id => '1337'

          response.response_code.should === 404
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it 'raises ActiveRecord::RecordNotFound errors' do
          get 'show', :id => '1337'

          response.response_code.should === 404
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'show', :id => planning_element.id

          response.response_code.should == 403
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        before do
          get 'show', :id => planning_element.id
        end

        it 'renders the show builder template' do
          response.should render_template('work_packages/show', :formats => ["html"], :layout => :base)
        end
      end
    end
  end

  describe 'show.pdf' do

    become_admin

    describe 'w/o a valid planning element id' do

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 404 page' do
          get 'show', :format => 'pdf',
                      :id => '1337'

          response.response_code.should === 404
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it 'raises ActiveRecord::RecordNotFound errors' do
          get 'show', :format => 'pdf',
                      :id => '1337'

          response.response_code.should === 404
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'show', :format => 'pdf',
                      :id => planning_element.id

          response.response_code.should == 403
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it "should respond with a pdf" do
          pdf = double('pdf')

          expected_name = "#{planning_element.project.identifier}-#{planning_element.id}.pdf"
          controller.stub!(:issue_to_pdf).and_return(pdf)
          controller.should_receive(:send_data).with(pdf,
                                                     :type => 'application/pdf',
                                                     :filename => expected_name).and_call_original
          get 'show', :format => 'pdf',
                      :id => planning_element.id
        end
      end
    end
  end

  describe 'new.html' do
    describe 'w/o specifying a project_id' do
      before do
        get 'new'
      end

      it 'should return 404 Not found' do
        response.response_code.should == 404
      end
    end

    describe 'w/o being a member' do
      before do
        get 'new', :project_id => project.id
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 403
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions' do
      become_member_with_permissions [:add_work_packages]

      before do
        get 'new', :project_id => project.id
      end

      it 'renders the new builder template' do
        response.should render_template('work_packages/new', :formats => ["html"])
      end

      it 'should respond with 200 OK' do
        response.response_code.should == 200
      end
    end

    describe 'w/ beeing a member
              w/o having the necessary permissions' do
      become_member_with_permissions []

      before do
        get 'new', :project_id => project.id
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 403
      end
    end
  end

  describe 'new_type.js' do
    describe 'w/o specifying a project_id or an id' do
      before do
        xhr :get, :new_type
      end

      it 'should return 403 Not found' do
        response.response_code.should == 403
      end
    end

    describe 'w/o being a member' do
      before do
        xhr :get, :new_type, :project_id => project.id
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 403
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions
              w/ specifying a project_id' do
      become_member_with_permissions [:add_work_packages]

      before do
        xhr :get, :new_type, :project_id => project.id
      end

      it 'renders the new builder template' do
        response.should render_template('work_packages/new_type', :formats => ["html"])
      end

      it 'should respond with 200 OK' do
        response.response_code.should == 200
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions
              w/ specifying an id' do
      become_member_with_permissions [:view_work_packages,
                                      :edit_work_packages]

      before do
        xhr :get, :new_type, :id => planning_element.id
      end

      it 'renders the new builder template' do
        response.should render_template('work_packages/new_type', :formats => ["html"])
      end

      it 'should respond with 200 OK' do
        response.response_code.should == 200
      end
    end

    describe 'w/ beeing a member
              w/o having the necessary permissions' do
      become_member_with_permissions []

      before do
        xhr :get, :new_type, :project_id => project.id
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 403
      end
    end
  end

  describe 'create.html' do
    describe 'w/o specifying a project_id' do
      before do
        post 'create'
      end

      it 'should return 404 Not found' do
        response.response_code.should == 404
      end
    end

    describe 'w/o being a member' do
      before do
        post 'create', :project_id => project.id
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 403
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions
              w/ having an successful save' do
      let(:params) { { :project_id => project.id, :work_package => { } } }

      become_member_with_permissions [:add_work_packages]

      before do
        controller.stub!(:new_work_package).and_return(stub_issue)
        stub_issue.should_receive(:save).and_return(true)
      end

      it 'redirect to show' do
        post 'create', params

        response.should redirect_to(work_package_path(stub_issue))
      end

      it 'should show a flash message' do
        disable_flash_sweep

        post 'create', params

        flash[:notice].should == I18n.t(:notice_successful_create)
      end

      it 'should attach attachments if those are provided' do
        params[:attachments] = 'attachment-blubs-data'

        Attachment.should_receive(:attach_files).with(stub_issue, params[:attachments])
        controller.stub!(:render_attachment_warning_if_needed)

        post 'create', params
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions
              w/ having an unsuccessful save' do
      become_member_with_permissions [:add_work_packages]

      before do
        controller.stub!(:new_work_package).and_return(stub_issue)
        stub_issue.should_receive(:save).and_return(false)

        post 'create', :project_id => project.id
      end

      it 'renders the new template' do
        response.should render_template('work_packages/new', :formats => ["html"])
      end
    end

    describe 'w/ beeing a member
              w/o having the necessary permissions' do
      become_member_with_permissions []

      before do
        get 'new', :project_id => project.id
      end

      it 'should return 403 Forbidden' do
        response.response_code.should == 403
      end
    end
  end

  describe 'edit.html' do

    become_admin

    describe 'w/o a valid work_package id' do

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 404 page' do
          get 'edit', :id => '1337'

          response.response_code.should === 404
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it 'raises ActiveRecord::RecordNotFound errors' do
          get 'edit', :id => '1337'

          response.response_code.should === 404
        end
      end
    end

    describe 'w/ a valid work package id' do
      become_admin

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'edit', :id => planning_element.id

          response.response_code.should == 403
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_permissions [:edit_work_packages]

        before do
          get 'edit', :id => planning_element.id
        end

        it 'renders the show builder template' do
          response.should render_template('work_packages/edit', :formats => ["html"], :layout => :base)
        end
      end
    end
  end

  describe 'update.html' do
    describe 'w/o being a member' do
      before do
        put 'update'
      end

      it 'should return 404 Not Found' do
        response.response_code.should == 404
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions
              w/ a valid wp id
              w/ having a successful save' do
      let(:wp_params) { { :wp_attribute => double('wp_attribute') } }
      let(:params) { { :id => planning_element.id, :work_package => wp_params } }

      become_member_with_permissions [:edit_work_packages]

      before do
        controller.stub!(:work_package).and_return(planning_element)
        controller.send(:permitted_params).should_receive(:update_work_package)
                                          .with(:project => planning_element.project)
                                          .and_return(wp_params)
        planning_element.should_receive(:update_by).with(current_user, wp_params).and_return(true)
      end

      it 'should respond with 200 OK' do
        put 'update', params

        response.response_code.should == 200
      end

      it 'should show a flash message' do
        disable_flash_sweep

        put 'update', params

        flash[:notice].should == I18n.t(:notice_successful_update)
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions
              w/ a valid wp id
              w/ having an unsuccessful save' do
      let(:wp_params) { { :wp_attribute => double('wp_attribute') } }
      let(:params) { { :id => planning_element.id, :work_package => wp_params } }

      become_member_with_permissions [:edit_work_packages]

      before do
        controller.stub!(:work_package).and_return(planning_element)
        controller.send(:permitted_params).should_receive(:update_work_package)
                                          .with(:project => planning_element.project)
                                          .and_return(wp_params)
        planning_element.should_receive(:update_by).with(current_user, wp_params).and_return(false)
      end

      it 'render the edit action' do
        put 'update', params

        response.should render_template('work_packages/edit', :formats => ["html"], :layout => :base)
      end
    end

    describe 'w/ beeing a member
              w/ having the necessary permissions
              w/ a valid wp id
              w/ having a successful save
              w/ having a faulty attachment' do
      let(:wp_params) { { :wp_attribute => double('wp_attribute') } }
      let(:params) { { :id => planning_element.id, :work_package => wp_params } }

      become_member_with_permissions [:edit_work_packages]

      before do
        controller.stub!(:work_package).and_return(planning_element)
        controller.send(:permitted_params).should_receive(:update_work_package)
                                          .with(:project => planning_element.project)
                                          .and_return(wp_params)
        planning_element.should_receive(:update_by).with(current_user, wp_params).and_return(true)
        planning_element.stub(:unsaved_attachments).and_return([double('unsaved_attachment')])
      end

      it 'should respond with 200 OK' do
        put 'update', params

        response.response_code.should == 200
      end

      it 'should show a flash message' do
        disable_flash_sweep

        put 'update', params

        flash[:warning].should == I18n.t(:warning_attachments_not_saved, :count => 1)
      end
    end
  end

  describe :work_package do
    describe 'when beeing allowed to see the work_package' do
      become_member_with_view_planning_element_permissions

      it 'should return the work_package' do
        controller.params = { id: planning_element.id }

        controller.work_package.should == planning_element
      end

      it 'should return nil for non existing work_packages' do
        controller.params = { id: 0 }

        controller.work_package.should be_nil
      end
    end

    describe 'when not beeing allowed to see the work_package' do
      it 'should return nil' do
        controller.params = { id: planning_element.id }

        controller.work_package.should be_nil
      end
    end
  end

  describe :new_work_package do
    describe 'when the type is "PlanningElement"' do
      before do
        controller.params = { :sti_type => 'PlanningElement',
                              :work_package => {} }
        controller.stub!(:project).and_return(project)
        controller.stub!(:current_user).and_return(stub_user)

        project.should_receive(:add_planning_element) do |args|

          expect(args[:author]).to eql stub_user

        end.and_return(stub_planning_element)
      end

      it 'should return a new planning element on the project' do
        controller.new_work_package.should == stub_planning_element
      end

      it 'should copy over attributes from another work_package provided as the source' do
        controller.params[:copy_from] = 2
        stub_planning_element.should_receive(:copy_from).with(2, :exclude => [:project_id])

        controller.new_work_package
      end
    end

    describe 'when the type is "Issue"' do
      before do
        controller.params = { :sti_type => 'Issue',
                              :work_package => {} }

        controller.stub!(:project).and_return(project)
        controller.stub!(:current_user).and_return(stub_user)

        project.should_receive(:add_issue) do |args|

          expect(args[:author]).to eql stub_user

        end.and_return(stub_issue)
      end

      it 'should return a new issue on the project' do
        controller.new_work_package.should == stub_issue
      end

      it 'should copy over attributes from another work_package provided as the source' do
        controller.params[:copy_from] = 2
        stub_issue.should_receive(:copy_from).with(2, :exclude => [:project_id])

        controller.new_work_package
      end
    end

    describe 'when the type is "Project"' do
      it "should raise not allowed" do
        controller.params = { :sti_type => 'Project' }

        expect { controller.new_work_package }.to raise_error ArgumentError
      end
    end
  end

  describe :project do
    it "should be the work_packages's project" do
      controller.stub!(:work_package).and_return(planning_element)

      controller.project.should == project
    end
  end

  describe :journals do
    it "should return all the work_package's journals except the first one" do
      journal = FactoryGirl.create(:planning_element_journal, journaled: planning_element,
                                                              changed_data: { description: [planning_element.description, "blubs"]},
                                                              version: 2
                                  )
      planning_element.reload

      controller.stub!(:work_package).and_return(planning_element)

      controller.journals.should == [journal]
    end

    it "should be empty if the work_package has only one journal" do
      controller.stub!(:work_package).and_return(planning_element)

      controller.journals.should be_empty
    end
  end

  describe :changesets do
    let(:change1) { double('change_1') }
    let(:change2) { double('change_2') }
    let(:changesets) { [change1, change2] }

    before do
      planning_element.stub!(:changesets).and_return(changesets)
      # couldn't get stub_chain to work
      # https://www.relishapp.com/rspec/rspec-mocks/v/2-0/docs/stubs/stub-a-chain-of-methods
      [:visible, :all, :includes].each do |meth|
        changesets.stub!(meth).and_return(changesets)
      end
      controller.stub!(:work_package).and_return(planning_element)
    end

    it "should have all the work_package's changesets" do
      controller.changesets.should == changesets
    end

    it "should have all the work_package's changesets in reverse order if the user wan'ts it that way" do
      controller.stub!(:current_user).and_return(stub_user)

      stub_user.stub!(:wants_comments_in_reverse_order?).and_return(true)

      controller.changesets.should == [change2, change1]
    end
  end

  describe :relations do
    let(:relation) { FactoryGirl.build_stubbed(:issue_relation, :issue_from => stub_issue,
                                                                :issue_to => stub_planning_element) }
    let(:relations) { [relation] }

    before do
      controller.stub!(:work_package).and_return(stub_issue)
      stub_issue.stub(:relations).and_return(relations)
      relations.stub!(:includes).and_return(relations)
    end

    it "should return all the work_packages's relations visible to the user" do
      stub_planning_element.stub!(:visible?).and_return(true)

      controller.relations.should == relations
    end

    it "should not return relations invisible to the user" do
      stub_planning_element.stub!(:visible?).and_return(false)

      controller.relations.should == []
    end
  end

  describe :ancestors do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:ancestor_issue) { FactoryGirl.create(:issue, :project => project) }
    let(:issue) { FactoryGirl.create(:issue, :project => project, :parent_id => ancestor_issue.id) }

    become_member_with_view_planning_element_permissions

    describe "when work_package is an issue" do
      let(:ancestor_issue) { FactoryGirl.create(:issue, :project => project) }
      let(:issue) { FactoryGirl.create(:issue, :project => project, :parent_id => ancestor_issue.id) }

      it "should return the work_packages ancestors" do
        controller.stub!(:work_package).and_return(issue)

        controller.ancestors.should == [ancestor_issue]
      end
    end

    describe "when work_package is a planning element" do
      let(:descendant_planning_element) { FactoryGirl.create(:planning_element, :project => project,
                                                                                :parent_id => planning_element.id) }
      it "should return the work_packages ancestors" do
        controller.stub!(:work_package).and_return(descendant_planning_element)

        controller.ancestors.should == [planning_element]
      end
    end
  end

  describe :descendants do
    it "should be empty" do
      controller.descendants.should be_empty
    end
  end

  describe :priorities do
    it "should return all defined priorities" do
      expected = double('priorities')

      IssuePriority.stub!(:all).and_return(expected)

      controller.priorities.should == expected
    end
  end

  describe :allowed_statuses do
    it "should return all statuses allowed by the issue" do
      expected = double('statuses')

      controller.stub!(:work_package).and_return(stub_issue)

      stub_issue.stub!(:new_statuses_allowed_to).with(current_user).and_return(expected)

      controller.allowed_statuses.should == expected
    end
  end

  describe :time_entry do
    before do
      controller.stub!(:work_package).and_return(stub_planning_element)
    end

    it "should return a time entry" do
      expected = double('time_entry')

      stub_planning_element.stub!(:add_time_entry).and_return(expected)

      controller.time_entry.should == expected
    end
  end

  describe 'preview.html' do
    let(:params) { { work_package: { notes: "My note" },
                     project_id: project.id } }

    before do
      controller.stub!(:work_package).and_return(stub_issue)
    end

    context "as an admin" do
      become_admin

      it 'render the edit action' do
        post 'preview', params

        response.should render_template('work_packages/preview', :formats => ["html"], :layout => false)
      end
    end

    context "as a project member" do
      become_member_with_permissions [:edit_work_packages]

      it 'render the edit action' do
        post 'preview', params

        response.should render_template('work_packages/preview', :formats => ["html"], :layout => false)
      end
    end

    context "as a non member" do
      become_non_member

      it 'render the edit action' do
        post 'preview', params

        response.response_code.should === 403
      end
    end
  end
end
