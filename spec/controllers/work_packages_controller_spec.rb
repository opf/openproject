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

describe WorkPackagesController do

  before do
    User.stub(:current).and_return current_user
    # disables sending mails
    UserMailer.stub!(:new).and_return(double('mailer').as_null_object)
  end

  let(:planning_element) { FactoryGirl.create(:planning_element, :project_id => project.id) }
  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:stub_planning_element) { FactoryGirl.build_stubbed(:planning_element, :project_id => stub_project.id) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project, :identifier => 'test_project', :is_public => false) }
  let(:stub_issue) { FactoryGirl.build_stubbed(:issue, :project_id => stub_project.id) }
  let(:stub_user) { FactoryGirl.build_stubbed(:user) }
  let(:stub_work_package) { double("work_package", :id => 1337, :project => stub_project).as_null_object }

  let(:current_user) { FactoryGirl.create(:user) }

  def self.requires_permission_in_project(&block)
    describe 'w/o the permission to see the project/work_package' do
      before do
        controller.stub(:work_package).and_return(nil)

        call_action
      end

      it 'should render a 404' do
        response.response_code.should === 404
      end
    end

    describe 'w/ the permission to see the project
              w/ having the necessary permissions' do

      before do
        controller.stub(:work_package).and_return(stub_work_package)
        controller.should_receive(:authorize).and_return(true)
      end

      instance_eval(&block)
    end
  end


  describe 'show.html' do
    let(:call_action) { get('show', :id => '1337') }

    requires_permission_in_project do
      it 'renders the show builder template' do
        call_action

        response.should render_template('work_packages/show', :formats => ["html"],
                                                              :layout => :base)
      end
    end
  end


  describe 'show.pdf' do
    let(:call_action) { get('show', :format => 'pdf', :id => '1337') }

    requires_permission_in_project do
      it 'respond with a pdf' do
        pdf = double('pdf')

        expected_name = "#{stub_work_package.project.identifier}-#{stub_work_package.id}.pdf"
        controller.stub!(:issue_to_pdf).and_return(pdf)
        controller.should_receive(:send_data).with(pdf,
                                                   :type => 'application/pdf',
                                                   :filename => expected_name).and_call_original
        call_action
      end
    end
  end


  describe 'new.html' do
    let(:call_action) { get('new', :format => 'html', :project_id => 5) }

    requires_permission_in_project do
      before do
        call_action
      end

      it 'renders the new builder template' do

        response.should render_template('work_packages/new', :formats => ["html"])
      end

      it 'should respond with 200 OK' do
        response.response_code.should == 200
      end
    end
  end


  describe 'new_type.js' do
    let(:wp_params) { { :wp_attribute => double('wp_attribute') } }
    let(:call_action) { xhr :get, :new_type, :project_id => 5 }

    requires_permission_in_project do
      before do
        controller.send(:permitted_params).should_receive(:update_work_package)
                                          .with(:project => stub_project)
                                          .and_return(wp_params)
        stub_work_package.should_receive(:update_by).with(current_user, wp_params).and_return(true)

        call_action
      end

      it 'renders the new builder template' do
        response.should render_template('work_packages/new_type', :formats => ["html"])
      end

      it 'should respond with 200 OK' do
        response.response_code.should == 200
      end
    end
  end


  describe 'create.html' do
    let(:params) { { :project_id => stub_work_package.project.id,
                     :work_package => { } } }

    let(:call_action) { post 'create', params }

    requires_permission_in_project do

      describe 'w/ having a successful save' do
        before do
          stub_work_package.should_receive(:save).and_return(true)
        end

        it 'redirect to show' do
          call_action

          response.should redirect_to(work_package_path(stub_work_package))
        end

        it 'should show a flash message' do
          disable_flash_sweep

          call_action

          flash[:notice].should == I18n.t(:notice_successful_create)
        end

        it 'should attach attachments if those are provided' do
          params[:attachments] = 'attachment-blubs-data'

          Attachment.should_receive(:attach_files).with(stub_work_package, params[:attachments])
          controller.stub!(:render_attachment_warning_if_needed)

          call_action
        end
      end

      describe 'w/ having an unsuccessful save' do

        before do
          stub_work_package.should_receive(:save).and_return(false)

          call_action
        end

        it 'renders the new template' do
          response.should render_template('work_packages/new', :formats => ["html"])
        end
      end
    end
  end

  describe 'edit.html' do
    let(:call_action) { get 'edit', :id => stub_work_package.id }

    requires_permission_in_project do
      it 'renders the show builder template' do
        call_action

        response.should render_template('work_packages/edit', :formats => ["html"], :layout => :base)
      end
    end
  end

  describe 'update.html' do
    let(:wp_params) { { :wp_attribute => double('wp_attribute') } }
    let(:params) { { :id => stub_work_package.id, :work_package => wp_params } }
    let(:call_action) { put 'update', params }

    requires_permission_in_project do
      before do
        controller.stub(:work_package).and_return(stub_work_package)
        controller.send(:permitted_params).should_receive(:update_work_package)
                                          .with(:project => stub_work_package.project)
                                          .and_return(wp_params)
      end

      describe 'w/ having a successful save' do
        before do
          stub_work_package.should_receive(:update_by!)
                           .with(current_user, wp_params)
                           .and_return(true)
        end

        it 'should respond with 200 OK' do
          call_action

          response.response_code.should == 200
        end

        it 'should show a flash message' do
          disable_flash_sweep

          call_action

          flash[:notice].should == I18n.t(:notice_successful_update)
        end
      end

      describe 'w/ having an unsuccessful save' do
        before do
          stub_work_package.should_receive(:update_by!)
                           .with(current_user, wp_params)
                           .and_return(false)
        end

        it 'render the edit action' do
          call_action

          response.should render_template('work_packages/edit', :formats => ["html"], :layout => :base)
        end
      end

      describe 'w/ having a successful save
                w/ having a faulty attachment' do

        before do
          stub_work_package.should_receive(:update_by!)
                           .with(current_user, wp_params)
                           .and_return(true)
          stub_work_package.stub(:unsaved_attachments)
                           .and_return([double('unsaved_attachment')])
        end

        it 'should respond with 200 OK' do
          call_action

          response.response_code.should == 200
        end

        it 'should show a flash message' do
          disable_flash_sweep

          call_action

          flash[:warning].should == I18n.t(:warning_attachments_not_saved, :count => 1)
        end
      end
    end
  end

  describe 'preview.html' do
    let(:wp_params) { { :wp_attribute => double('wp_attribute') } }
    let(:params) { { work_package: wp_params } }
    let(:call_action) { post 'preview', params }

    requires_permission_in_project do
      before do
        controller.stub(:work_package).and_return(stub_work_package)
        controller.send(:permitted_params).should_receive(:update_work_package)
                                          .with(:project => stub_work_package.project)
                                          .and_return(wp_params)
      end

      it 'render the preview ' do
        call_action

        response.should render_template('work_packages/preview', :formats => ["html"], :layout => false)
      end
    end
  end

  describe 'preview.js' do
    let(:wp_params) { { :wp_attribute => double('wp_attribute') } }
    let(:params) { { work_package: wp_params } }
    let(:call_action) { xhr :post, :preview, params }

    requires_permission_in_project do
      before do
        controller.stub(:work_package).and_return(stub_work_package)
        controller.send(:permitted_params).should_receive(:update_work_package)
                                          .with(:project => stub_work_package.project)
                                          .and_return(wp_params)
      end

      it 'render the preview ' do
        call_action

        response.should render_template('work_packages/preview', :formats => ["html"], :layout => false)
      end
    end
  end

  describe :work_package do
    describe 'when providing an id (wanting to see an existing wp)' do
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

    describe 'when providing a project_id (wanting to build a new wp)' do
      let(:wp_params) { { :wp_attribute => double('wp_attribute') } }
      let(:params) { { :project_id => stub_project.id } }

      before do
        Project.stub(:find_visible).and_return stub_project
      end

      describe 'when the type is "PlanningElement"' do
        before do
          controller.params = { :sti_type => 'PlanningElement',
                                :work_package => {} }.merge(params)

          controller.stub(:current_user).and_return(stub_user)
          controller.send(:permitted_params).should_receive(:new_work_package)
                                            .with(:project => stub_project)
                                            .and_return(wp_params)

          stub_project.should_receive(:add_planning_element) do |args|

            expect(args[:author]).to eql stub_user

          end.and_return(stub_planning_element)
        end

        it 'should return a new planning element on the project' do
          controller.work_package.should == stub_planning_element
        end

        it 'should copy over attributes from another work_package provided as the source' do
          controller.params[:copy_from] = 2
          stub_planning_element.should_receive(:copy_from).with(2, :exclude => [:project_id])

          controller.work_package
        end
      end

      describe 'when the type is "Issue"' do
        before do
          controller.params = { :sti_type => 'Issue',
                                :work_package => {} }.merge(params)

          controller.stub(:current_user).and_return(stub_user)
          controller.send(:permitted_params).should_receive(:new_work_package)
                                            .with(:project => stub_project)
                                            .and_return(wp_params)

          stub_project.should_receive(:add_issue) do |args|

            expect(args[:author]).to eql stub_user

          end.and_return(stub_issue)
        end

        it 'should return a new issue on the project' do
          controller.work_package.should == stub_issue
        end

        it 'should copy over attributes from another work_package provided as the source' do
          controller.params[:copy_from] = 2
          stub_issue.should_receive(:copy_from).with(2, :exclude => [:project_id])

          controller.work_package
        end
      end

      describe 'if the project is not visible for the current_user' do
        before do
          projects = [stub_project]
          Project.stub(:visible).and_return projects
          projects.stub(:find_by_id).and_return(stub_project)
        end

        it 'should return nil' do
          controller.work_package.should be_nil

        end
      end

      describe 'when the sti_type is "Project"' do
        it "should raise not allowed" do
          controller.params = { :sti_type => 'Project',
                                :project_id => stub_project.id }.merge(params)

          expect { controller.work_package }.to raise_error ArgumentError
        end
      end
    end

    describe 'when providing neither id nor project_id (error)' do
      it "should return nil" do
        controller.params = {}

        controller.work_package.should be_nil
      end
    end
  end

  describe :project do
    it "should be the work_packages's project" do
      controller.stub(:work_package).and_return(planning_element)

      controller.project.should == planning_element.project
    end
  end

  describe :journals do
    it "should return all the work_package's journals except the first one" do
      planning_element.description = "blubs"

      planning_element.save
      planning_element.reload

      controller.stub!(:work_package).and_return(planning_element)

      controller.journals.should == [planning_element.journals.last]
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
    before do
      controller.stub(:work_package).and_return(planning_element)
    end

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

end
