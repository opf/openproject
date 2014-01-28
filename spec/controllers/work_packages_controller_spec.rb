#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackagesController do

  before do
    User.stub(:current).and_return current_user
    # disables sending mails
    UserMailer.stub(:new).and_return(double('mailer').as_null_object)
  end

  let(:planning_element) { FactoryGirl.create(:work_package, :project_id => project.id) }
  let(:project) { FactoryGirl.create(:project, :identifier => 'test_project', :is_public => false) }
  let(:stub_planning_element) { FactoryGirl.build_stubbed(:work_package, :project_id => stub_project.id) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project, :identifier => 'test_project', :is_public => false) }
  let(:stub_issue) { FactoryGirl.build_stubbed(:work_package, :project_id => stub_project.id) }
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

  def self.requires_export_permission(&block)

    describe 'w/ the export permission
              w/o a project' do
      let(:project) { nil }

      before do
        User.current.should_receive(:allowed_to?)
                    .with(:export_work_packages,
                          project,
                          :global => true)
                    .and_return(true)
      end

      instance_eval(&block)
    end

    describe 'w/ the export permission
              w/ a project' do
      before do
        params[:project_id] = project.id

        User.current.should_receive(:allowed_to?)
                    .with(:export_work_packages,
                          project,
                          :global => false)
                    .and_return(true)
      end

      instance_eval(&block)
    end

    describe 'w/o the export permission' do
      let(:project) { nil }

      before do
        User.current.should_receive(:allowed_to?)
                    .with(:export_work_packages,
                          project,
                          :global => true)
                    .and_return(false)

        call_action
      end

      it 'should render a 403' do
        response.response_code.should == 403
      end
    end
  end

  describe 'index' do
    let(:query) { FactoryGirl.build_stubbed(:query).tap(&:add_default_filter) }
    let(:work_packages) { double("work packages").as_null_object }

    before do
      User.current.should_receive(:allowed_to?)
                  .with({ :controller => "work_packages",
                          :action => "index" },
                        project,
                        :global => true)
                  .and_return(true)

      controller.stub(:retrieve_query).and_return(query)
      query.stub_chain(:results, :work_packages, :page, :per_page, :all).and_return(work_packages)
    end

    describe 'html' do
      let(:call_action) { get('index', :project_id => project.id) }
      before { call_action }

      describe "w/o a project" do
        let(:project) { nil }
        let(:call_action) { get('index') }

        it 'should render the index template' do
          response.should render_template('work_packages/index', :formats => ["html"],
                                                                 :layout => :base)
        end
      end

      context "w/ a project" do
        it 'should render the index template' do
          response.should render_template('work_packages/index', :formats => ["html"],
                                                                 :layout => :base)
        end
      end

      context 'when a query has been previously selected' do
        let(:query) do
          FactoryGirl.build_stubbed(:query).tap {|q| q.filters = [Queries::WorkPackages::Filter.new('done_ratio', operator: ">=", values: [10]) ]}
        end

        before { session.stub(:query).and_return query }

        it 'preserves the query' do
          assigns['query'].filters.should == query.filters
        end
      end
    end

    describe 'csv' do
      let(:params) { {} }
      let(:call_action) { get('index', params.merge(:format => 'csv')) }

      requires_export_permission do

        before do
          mock_csv = double('csv export')

          WorkPackage::Exporter.should_receive(:csv).with(work_packages, project)
                                                    .and_return(mock_csv)

          controller.should_receive(:send_data).with(mock_csv,
                                                     :type => 'text/csv; header=present',
                                                     :filename => 'export.csv') do |*args|
            # We need to render something because otherwise
            # the controller will and he will not find a suitable template
            controller.render :text => "success"
          end
        end

        it 'should fulfill the defined should_receives' do
          call_action
        end
      end
    end

    describe 'pdf' do
      let(:params) { {} }
      let(:call_action) { get('index', params.merge(:format => 'pdf')) }

      requires_export_permission do
        before do
          mock_pdf = double('pdf export')

          WorkPackage::Exporter.should_receive(:pdf).and_return(mock_pdf)

          controller.should_receive(:send_data).with(mock_pdf,
                                                     :type => 'application/pdf',
                                                     :filename => 'export.pdf') do |*args|
            # We need to render something because otherwise
            # the controller will and he will not find a suitable template
            controller.render :text => "success"
          end
        end

        it 'should fulfill the defined should_receives' do
          call_action
        end
      end
    end

    describe 'atom' do
      let(:params) { {} }
      let(:call_action) { get('index', params.merge(:format => 'atom')) }

      requires_export_permission do
        before do
          controller.should_receive(:render_feed).with(work_packages, anything()) do |*args|
            # We need to render something because otherwise
            # the controller will and he will not find a suitable template
            controller.render :text => "success"
          end
        end

        it 'should fulfill the defined should_receives' do
          call_action
        end
      end
    end

  end

  describe 'index with a broken project reference' do
    before { get('index', :project_id => 'project_that_doesnt_exist') }

    it { should respond_with :not_found }
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
        WorkPackage::Exporter.should_receive(:work_package_to_pdf).and_return(pdf)
        controller.should_receive(:send_data).with(pdf,
                                                   :type => 'application/pdf',
                                                   :filename => expected_name) do |*args|
          # We need to render something because otherwise
          # the controller will and he will not find a suitable template
          controller.render :text => "success"
        end
        call_action
      end
    end
  end

  describe 'show.atom' do
    let(:call_action) { get('show', :format => 'atom', :id => '1337') }

    requires_permission_in_project do
      it 'render the journal/index template' do
        call_action

        response.should render_template('journals/index', :formats => ["atom"],
                                                          :layout => false,
                                                          :content_type => 'application/atom+xml')
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

          stub_work_package.should_receive(:attach_files).with(params[:attachments])
          controller.stub(:render_attachment_warning_if_needed)

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
                                          .at_most(:twice)
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

      describe 'when we copy stuff' do
        before do
          controller.params = { :work_package => {} }.merge(params)

          controller.stub(:current_user).and_return(stub_user)
          controller.send(:permitted_params).should_receive(:new_work_package)
                                            .with(:project => stub_project)
                                            .and_return(wp_params)

          stub_project.should_receive(:add_work_package) do |args|

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

      controller.stub(:work_package).and_return(planning_element)

      controller.journals.should == [planning_element.journals.last]
    end

    it "should be empty if the work_package has only one journal" do
      controller.stub(:work_package).and_return(planning_element)

      controller.journals.should be_empty
    end


    describe "order of journal entries" do
      let!(:planning_element_note1) { FactoryGirl.create(:work_package_journal,
                                                  journable_id: planning_element.id,
                                                  version: 2,
                                                  notes: 'lala')}

      let!(:planning_element_note2) { FactoryGirl.create(:work_package_journal,
                                                  journable_id: planning_element.id,
                                                  version: 3,
                                                  notes: 'lala2')}

      before do
        controller.stub(:current_user).and_return(stub_user)
        controller.stub(:work_package).and_return(planning_element)
      end

      it "chronological by default" do
        controller.journals.should == [planning_element_note1, planning_element_note2]
      end

      it "reverse chronological order if the user wan'ts it that way" do
        stub_user.stub(:wants_comments_in_reverse_order?).and_return(true)
        controller.journals.should == [planning_element_note2, planning_element_note1]
      end
    end
  end

  describe :changesets do
    let(:change1) { double('change_1') }
    let(:change2) { double('change_2') }
    let(:changesets) { [change1, change2] }

    before do
      planning_element.stub(:changesets).and_return(changesets)
      # couldn't get stub_chain to work
      # https://www.relishapp.com/rspec/rspec-mocks/v/2-0/docs/stubs/stub-a-chain-of-methods
      [:visible, :all, :includes].each do |meth|
        changesets.stub(meth).and_return(changesets)
      end
      controller.stub(:work_package).and_return(planning_element)
    end

    it "should have all the work_package's changesets" do
      controller.changesets.should == changesets
    end

    it "should have all the work_package's changesets in reverse order if the user wan'ts it that way" do
      controller.stub(:current_user).and_return(stub_user)

      stub_user.stub(:wants_comments_in_reverse_order?).and_return(true)

      controller.changesets.should == [change2, change1]
    end
  end

  describe :relations do
    let(:relation) { FactoryGirl.build_stubbed(:relation, :from => stub_issue,
                                                                :to => stub_planning_element) }
    let(:relations) { [relation] }

    before do
      controller.stub(:work_package).and_return(stub_issue)
      stub_issue.stub(:relations).and_return(relations)
      relations.stub(:includes).and_return(relations)
    end

    it "should return all the work_packages's relations visible to the user" do
      stub_planning_element.stub(:visible?).and_return(true)

      controller.relations.should == relations
    end

    it "should not return relations invisible to the user" do
      stub_planning_element.stub(:visible?).and_return(false)

      controller.relations.should == []
    end
  end

  describe :ancestors do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:ancestor_issue) { FactoryGirl.create(:work_package, :project => project) }
    let(:issue) { FactoryGirl.create(:work_package, :project => project, :parent_id => ancestor_issue.id) }

    become_member_with_view_planning_element_permissions

    describe "when work_package is an issue" do
      let(:ancestor_issue) { FactoryGirl.create(:work_package, :project => project) }
      let(:issue) { FactoryGirl.create(:work_package, :project => project, :parent_id => ancestor_issue.id) }

      it "should return the work_packages ancestors" do
        controller.stub(:work_package).and_return(issue)

        controller.ancestors.should == [ancestor_issue]
      end
    end

    describe "when work_package is a planning element" do
      let(:descendant_planning_element) { FactoryGirl.create(:work_package, :project => project,
                                                                                :parent_id => planning_element.id) }
      it "should return the work_packages ancestors" do
        controller.stub(:work_package).and_return(descendant_planning_element)

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

      IssuePriority.stub(:all).and_return(expected)

      controller.priorities.should == expected
    end
  end

  describe :allowed_statuses do
    it "should return all statuses allowed by the issue" do
      expected = double('statuses')

      controller.stub(:work_package).and_return(stub_issue)

      stub_issue.stub(:new_statuses_allowed_to).with(current_user).and_return(expected)

      controller.allowed_statuses.should == expected
    end
  end

  describe :time_entry do
    before do
      controller.stub(:work_package).and_return(stub_planning_element)
    end

    it "should return a time entry" do
      expected = double('time_entry')

      stub_planning_element.stub(:add_time_entry).and_return(expected)

      controller.time_entry.should == expected
    end
  end

  describe "quotation" do
    let(:call_action) { get :quoted }

    requires_permission_in_project do
      context "description" do
        subject { get :quoted, id: planning_element.id }

        it { should be_success }
        it { should render_template('edit') }
      end

      context "journal" do
        let(:journal_id) { planning_element.journals.first.id }

        subject { get :quoted, id: planning_element.id, journal_id: journal_id }

        it { should be_success }
        it { should render_template('edit') }
      end
    end
  end

  let(:filename) { "test1.test" }

  describe :create do
    let(:type) { FactoryGirl.create :type }
    let(:project) { FactoryGirl.create :project,
                                       types: [type] }
    let(:status) { FactoryGirl.create :default_status }
    let(:priority) { FactoryGirl.create :priority }

    context :copy do
      let(:current_user) { FactoryGirl.create(:admin) }
      let(:params) { { copy_from: planning_element.id, project_id: project.id } }
      let(:except) { ["id",
                      "root_id",
                      "parent_id",
                      "lft",
                      "rgt",
                      "type",
                      "created_at",
                      "updated_at"] }

      before { post 'create', params }

      subject { response }

      it do
        assigns['new_work_package'].should_not == nil
        assigns['new_work_package'].attributes.dup.except(*except).should == planning_element.attributes.dup.except(*except)
      end
    end

    context :attachments do
      let(:new_work_package) { FactoryGirl.build(:work_package,
                                                 project: project,
                                                 type: type,
                                                 description: "Description",
                                                 priority: priority) }
      let(:params) { { project_id: project.id,
                       attachments: { file: { file: filename,
                                              description: '' } } } }

      before do
        controller.stub(:work_package).and_return(new_work_package)
        controller.should_receive(:authorize).and_return(true)

        Attachment.any_instance.stub(:filename).and_return(filename)
        Attachment.any_instance.stub(:copy_file_to_destination)
      end

      # see ticket #2009 on OpenProject.org
      context "new attachment on new work package" do
        before { post 'create', params }

        describe :journal do
          let(:attachment_id) { "attachments_#{new_work_package.attachments.first.id}".to_sym }

          subject { new_work_package.journals.last.changed_data }

          it { should have_key attachment_id }

          it { subject[attachment_id].should eq([nil, filename]) }
        end
      end

      context "invalid attachment" do
        let(:max_filesize) { Setting.attachment_max_size.to_i.kilobytes }

        before do
          Attachment.any_instance.stub(:filesize).and_return(max_filesize + 1)

          post :create, params
        end

        describe :view do
          subject { response }

          it { should render_template('work_packages/new', formats: ["html"]) }
        end

        describe :error do
          subject { new_work_package.errors.messages }

          it { should have_key(:attachments) }

          it { subject[:attachments] =~ /too long/ }
        end
      end
    end
  end

  describe :update do
    let(:type) { FactoryGirl.create :type }
    let(:project) { FactoryGirl.create :project,
                                       types: [type] }
    let(:status) { FactoryGirl.create :default_status }
    let(:priority) { FactoryGirl.create :priority }

    context :attachments do
      let(:work_package) { FactoryGirl.build(:work_package,
                                             project: project,
                                             type: type,
                                             description: "Description",
                                             priority: priority) }
      let(:params) { { id: work_package.id,
                       work_package: { attachments: { '1' =>  { file: filename,
                                                                description: '' } } } } }

      before do
        controller.stub(:work_package).and_return(work_package)
        controller.should_receive(:authorize).and_return(true)

        Attachment.any_instance.stub(:filename).and_return(filename)
        Attachment.any_instance.stub(:copy_file_to_destination)
      end

      context "invalid attachment" do
        let(:max_filesize) { Setting.attachment_max_size.to_i.kilobytes }

        before do
          Attachment.any_instance.stub(:filesize).and_return(max_filesize + 1)

          post :update, params
        end

        describe :view do
          subject { response }

          it { should render_template('work_packages/edit', formats: ["html"]) }
        end

        describe :error do
          subject { work_package.errors.messages }

          it { should have_key(:attachments) }

          it { subject[:attachments] =~ /too long/ }
        end
      end
    end
  end
end
