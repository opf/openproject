#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
require 'support/shared/previews'

describe WorkPackagesController, type: :controller do

  before do
    allow(User).to receive(:current).and_return current_user
    # disables sending mails
    allow(UserMailer).to receive(:new).and_return(double('mailer').as_null_object)
  end

  let(:planning_element) { FactoryGirl.create(:work_package, project_id: project.id) }
  let(:project) { FactoryGirl.create(:project, identifier: 'test_project', is_public: false) }
  let(:stub_planning_element) { FactoryGirl.build_stubbed(:work_package, project_id: stub_project.id) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project, identifier: 'test_project', is_public: false) }
  let(:stub_issue) { FactoryGirl.build_stubbed(:work_package, project_id: stub_project.id) }
  let(:stub_user) { FactoryGirl.build_stubbed(:user) }
  let(:stub_work_package) { double('work_package', id: 1337, project: stub_project).as_null_object }

  let(:current_user) { FactoryGirl.create(:user) }

  def self.requires_permission_in_project(&block)
    describe 'w/o the permission to see the project/work_package' do
      before do
        allow(controller).to receive(:work_package).and_return(nil)

        call_action
      end

      it 'should render a 404' do
        expect(response.response_code).to be === 404
      end
    end

    describe 'w/ the permission to see the project
              w/ having the necessary permissions' do

      before do
        allow(controller).to receive(:work_package).and_return(stub_work_package)
        expect(controller).to receive(:authorize).and_return(true)
      end

      instance_eval(&block)
    end
  end

  def self.requires_export_permission(&block)
    describe 'w/ the export permission
              w/o a project' do
      let(:project) { nil }

      before do
        expect(User.current).to receive(:allowed_to?)
          .with(:export_work_packages,
                project,
                global: true)
          .and_return(true)
      end

      instance_eval(&block)
    end

    describe 'w/ the export permission
              w/ a project' do
      before do
        params[:project_id] = project.id

        expect(User.current).to receive(:allowed_to?)
          .with(:export_work_packages,
                project,
                global: false)
          .and_return(true)
      end

      instance_eval(&block)
    end

    describe 'w/o the export permission' do
      let(:project) { nil }

      before do
        expect(User.current).to receive(:allowed_to?)
          .with(:export_work_packages,
                project,
                global: true)
          .and_return(false)

        call_action
      end

      it 'should render a 403' do
        expect(response.response_code).to eq(403)
      end
    end
  end

  describe 'index' do
    let(:query) { FactoryGirl.build_stubbed(:query).tap(&:add_default_filter) }
    let(:work_packages) { double('work packages').as_null_object }

    before do
      allow(User.current).to receive(:allowed_to?).and_return(false)
      expect(User.current).to receive(:allowed_to?)
        .with({ controller: 'work_packages',
                action: 'index' },
              project,
              global: true)
        .and_return(true)
    end

    describe 'with valid query' do
      before do
        allow(controller).to receive(:retrieve_query).and_return(query)

        # Note: Stubs for methods used to build up the json query results.
        # TODO RS:  Clearly this isn't testing anything, but it all needs to be moved to an API controller anyway.
        allow(query).to receive_message_chain(:results, :work_packages, :page, :per_page, :all).and_return(work_packages)
        allow(query).to receive_message_chain(:results, :work_package_count_by_group).and_return([])
        allow(query).to receive_message_chain(:results, :column_total_sums).and_return([])
        allow(query).to receive_message_chain(:results, :column_group_sums).and_return([])
        allow(query).to receive(:as_json).and_return('')
      end

      describe 'html' do
        let(:call_action) { get('index', project_id: project.id) }
        before { call_action }

        describe 'w/o a project' do
          let(:project) { nil }
          let(:call_action) { get('index') }

          it 'should render the index template' do
            expect(response).to render_template('work_packages/index', formats: ['html'],
                                                                       layout: :base)
          end
        end

        context 'w/ a project' do
          it 'should render the index template' do
            expect(response).to render_template('work_packages/index', formats: ['html'],
                                                                       layout: :base)
          end
        end

        context 'when a query has been previously selected' do
          let(:query) do
            FactoryGirl.build_stubbed(:query).tap { |q| q.filters = [Queries::WorkPackages::Filter.new('done_ratio', operator: '>=', values: [10])] }
          end

          before { allow(session).to receive(:query).and_return query }

          it 'preserves the query' do
            expect(assigns['query'].filters).to eq(query.filters)
          end
        end
      end

      describe 'csv' do
        let(:params) { {} }
        let(:call_action) { get('index', params.merge(format: 'csv')) }

        requires_export_permission do

          before do
            mock_csv = double('csv export')

            expect(WorkPackage::Exporter).to receive(:csv).with(work_packages, query)
                                                          .and_return(mock_csv)

            expect(controller).to receive(:send_data).with(mock_csv,
                                                           type: 'text/csv; charset=utf-8; header=present',
                                                           filename: "#{query.name}.csv") do |_|

              # We need to render something because otherwise
              # the controller will and he will not find a suitable template
              controller.render text: 'success'
            end
          end

          it 'should fulfill the defined should_receives' do
            call_action
          end
        end
      end

      describe 'pdf' do
        let(:params) { {} }
        let(:call_action) { get('index', params.merge(format: 'pdf')) }

        requires_export_permission do
          before do
            mock_pdf = double('pdf export')

            expect(WorkPackage::Exporter).to receive(:pdf).and_return(mock_pdf)

            expect(controller).to receive(:send_data).with(mock_pdf,
                                                           type: 'application/pdf',
                                                           filename: 'export.pdf') do |*_args|
              # We need to render something because otherwise
              # the controller will and he will not find a suitable template
              controller.render text: 'success'
            end
          end

          it 'should fulfill the defined should_receives' do
            call_action
          end
        end
      end

      describe 'atom' do
        let(:params) { {} }
        let(:call_action) { get('index', params.merge(format: 'atom')) }

        requires_export_permission do
          before do
            expect(controller).to receive(:render_feed).with(work_packages, anything) do |*_args|
              # We need to render something because otherwise
              # the controller will and he will not find a suitable template
              controller.render text: 'success'
            end
          end

          it 'should fulfill the defined should_receives' do
            call_action
          end
        end
      end
    end

    describe 'with invalid query' do
      context 'when a non-existant query has been previously selected' do
        let(:call_action) { get('index', project_id: project.id, query_id: 'hokusbogus') }
        before { call_action }

        it 'renders a 404' do
          expect(response.response_code).to be === 404
        end

        it 'preserves the project' do
          expect(assigns['project']).to be === project
        end
      end
    end
  end

  describe 'index with actual data' do
    require 'csv'
    render_views

    ##
    # When Ruby tries to join the following work package's subject encoded in ISO-8859-1
    # and its description encoded in UTF-8 it will result in a CompatibilityError.
    # This would not happen if the description contained only letters covered by
    # ISO-8859-1. Since this can happen, though, it is more sensible to encode everything
    # in UTF-8 which gets rid of this problem altogether.
    let(:work_package) do
      FactoryGirl.create(
        :work_package,
        subject: "Ruby encodes ß as '\\xDF' in ISO-8859-1.",
        description: "\u2022 requires unicode.")
    end
    let(:current_user) { FactoryGirl.create(:admin) }

    it 'performs a successful export' do
      wp = work_package

      expect {
        get :index, format: 'csv'
      }.not_to raise_error

      data = CSV.parse(response.body)

      expect(data.size).to eq(2)
      expect(data.last).to include(wp.subject)
      expect(data.last).to include(wp.description)
    end
  end

  describe 'index with a broken project reference' do
    before { get('index', project_id: 'project_that_doesnt_exist') }

    it { is_expected.to respond_with :not_found }
  end

  describe 'show.html' do
    let(:call_action) { get('show', id: '1337') }

    requires_permission_in_project do
      it 'renders the show builder template' do
        call_action

        expect(response).to render_template('work_packages/show', formats: ['html'],
                                                                  layout: :base)
      end
    end
  end

  describe 'show.pdf' do
    let(:call_action) { get('show', format: 'pdf', id: '1337') }

    requires_permission_in_project do
      it 'respond with a pdf' do
        pdf = double('pdf')

        expected_name = "#{stub_work_package.project.identifier}-#{stub_work_package.id}.pdf"
        expect(WorkPackage::Exporter).to receive(:work_package_to_pdf).and_return(pdf)
        expect(controller).to receive(:send_data).with(pdf,
                                                       type: 'application/pdf',
                                                       filename: expected_name) do |*_args|
          # We need to render something because otherwise
          # the controller will and he will not find a suitable template
          controller.render text: 'success'
        end
        call_action
      end
    end
  end

  describe 'show.atom' do
    let(:call_action) { get('show', format: 'atom', id: '1337') }

    requires_permission_in_project do
      it 'render the journal/index template' do
        call_action

        expect(response).to render_template('journals/index', formats: ['atom'],
                                                              layout: false,
                                                              content_type: 'application/atom+xml')
      end
    end
  end

  describe 'new.html' do
    let(:call_action) { get('new', format: 'html', project_id: 5) }

    requires_permission_in_project do
      before do
        call_action
      end

      it 'renders the new builder template' do

        expect(response).to render_template('work_packages/new', formats: ['html'])
      end

      it 'should respond with 200 OK' do
        expect(response.response_code).to eq(200)
      end
    end
  end

  describe 'new_type.js' do
    let(:wp_params) { { wp_attribute: double('wp_attribute') } }
    let(:call_action) { xhr :get, :new_type, project_id: 5 }

    requires_permission_in_project do
      before do
        expect(controller.send(:permitted_params)).to receive(:update_work_package)
          .with(project: stub_project)
          .and_return(wp_params)
        expect(stub_work_package).to receive(:update_by).with(current_user, wp_params).and_return(true)

        call_action
      end

      it 'renders the new builder template' do
        expect(response).to render_template('work_packages/new_type', formats: ['html'])
      end

      it 'should respond with 200 OK' do
        expect(response.response_code).to eq(200)
      end
    end
  end

  describe 'create.html' do
    let(:params) {
      { project_id: stub_work_package.project.id,
        work_package: {} }
    }

    let(:call_action) { post 'create', params }

    requires_permission_in_project do

      describe 'w/ having a successful save' do
        before do
          expect(stub_work_package).to receive(:save).and_return(true)
        end

        it 'redirect to show' do
          call_action

          expect(response).to redirect_to(work_package_path(stub_work_package))
        end

        it 'should show a flash message' do
          disable_flash_sweep

          call_action

          expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
        end

        it 'should attach attachments if those are provided' do
          params[:attachments] = 'attachment-blubs-data'

          expect(stub_work_package).to receive(:attach_files).with(params[:attachments])
          allow(controller).to receive(:render_attachment_warning_if_needed)

          call_action
        end
      end

      describe 'w/ having an unsuccessful save' do

        before do
          expect(stub_work_package).to receive(:save).and_return(false)

          call_action
        end

        it 'renders the new template' do
          expect(response).to render_template('work_packages/new', formats: ['html'])
        end
      end
    end
  end

  describe 'edit.html' do
    let(:call_action) { get 'edit', id: stub_work_package.id }

    requires_permission_in_project do
      it 'renders the show builder template' do
        call_action

        expect(response).to render_template('work_packages/edit', formats: ['html'], layout: :base)
      end
    end
  end

  describe 'update w/ a time entry' do
    render_views

    let(:admin) { FactoryGirl.create(:admin) }
    let(:work_package) { FactoryGirl.create(:work_package) }
    let(:default_activity) { FactoryGirl.create(:default_activity) }
    let(:activity) { FactoryGirl.create(:activity) }
    let(:params) do
      lambda do |work_package_id, activity_id|
        {
          id: work_package_id,
          work_package: {
            time_entry: {
              hours: '',
              comments: '',
              activity_id: activity_id
            }
          }
        }
      end
    end

    before do
      allow(User).to receive(:current).and_return admin
    end

    it 'should not try to create a time entry if blank' do
      # default activity counts as blank as long as everything else is blank too
      put 'update', params.call(work_package.id, default_activity.id)

      expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))
      expect(response).to redirect_to(work_package_path(work_package))
    end

    it 'should still give an error for a non-blank time entry' do
      put 'update', params.call(work_package.id, activity.id)

      expect(response.status).to eq(200) # shouldn't this be 400 or similar?
      expect(response.body).to have_content('Log time is invalid')
    end
  end

  describe 'update.html' do
    let(:wp_params) { { 'wp_attribute' => double('wp_attribute') } }
    let(:params) { { id: stub_work_package.id, work_package: wp_params } }
    let(:call_action) { put 'update', params }

    requires_permission_in_project do
      before do
        allow(controller).to receive(:work_package).and_return(stub_work_package)
        expect(controller.send(:permitted_params)).to receive(:update_work_package)
          .at_most(:twice)
          .with(project: stub_work_package.project)
          .and_return(wp_params)

        expect(current_user).to receive(:allowed_to?).with(:edit_work_packages, stub_work_package.project)
          .and_return(true)
      end

      describe 'w/ having a successful save' do
        before do
          expect(stub_work_package).to receive(:update_by!)
            .with(current_user, wp_params)
            .and_return(true)
        end

        it 'should redirect to the show action' do
          call_action

          expect(response).to redirect_to(work_package_path(stub_work_package))
        end

        it 'should show a flash message' do
          disable_flash_sweep

          call_action

          expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))
        end
      end

      describe 'w/ having an unsuccessful save' do
        before do
          expect(stub_work_package).to receive(:update_by!)
            .with(current_user, wp_params)
            .and_return(false)
        end

        it 'render the edit action' do
          call_action

          expect(response).to render_template('work_packages/edit', formats: ['html'], layout: :base)
        end
      end

      describe 'w/ having a successful save
                w/ having a faulty attachment' do

        before do
          expect(stub_work_package).to receive(:update_by!)
            .with(current_user, wp_params)
            .and_return(true)
          allow(stub_work_package).to receive(:unsaved_attachments)
            .and_return([double('unsaved_attachment')])
        end

        it 'should redirect to the show action' do
          call_action

          expect(response).to redirect_to(work_package_path(stub_work_package))
        end

        it 'should show a flash message' do
          disable_flash_sweep

          call_action

          expect(flash[:warning]).to eq(I18n.t(:warning_attachments_not_saved, count: 1))
        end
      end
    end
  end

  describe '#work_package' do
    describe 'when providing an id (wanting to see an existing wp)' do
      describe 'when beeing allowed to see the work_package' do
        become_member_with_view_planning_element_permissions

        it 'should return the work_package' do
          controller.params = { id: planning_element.id }

          expect(controller.work_package).to eq(planning_element)
        end

        it 'should return nil for non existing work_packages' do
          controller.params = { id: 0 }

          expect(controller.work_package).to be_nil
        end
      end

      describe 'when not beeing allowed to see the work_package' do
        it 'should return nil' do
          controller.params = { id: planning_element.id }

          expect(controller.work_package).to be_nil
        end
      end
    end

    describe 'when providing a project_id (wanting to build a new wp)' do
      let(:wp_params) { { wp_attribute: double('wp_attribute') } }
      let(:params) { { project_id: stub_project.id } }

      before do
        allow(Project).to receive(:find_visible).and_return stub_project
      end

      describe 'when we copy stuff' do
        before do
          controller.params = { work_package: {} }.merge(params)

          allow(controller).to receive(:current_user).and_return(stub_user)
          expect(controller.send(:permitted_params)).to receive(:new_work_package)
            .with(project: stub_project)
            .and_return(wp_params)

          expect(stub_project).to receive(:add_work_package) { |args|

            expect(args[:author]).to eql stub_user

          }.and_return(stub_issue)
        end

        it 'should return a new issue on the project' do
          expect(controller.work_package).to eq(stub_issue)
        end

        it 'should copy over attributes from another work_package provided as the source' do
          controller.params[:copy_from] = 2
          expect(stub_issue).to receive(:copy_from).with(2, exclude: [:project_id])

          controller.work_package
        end
      end

      describe 'if the project is not visible for the current_user' do
        before do
          projects = [stub_project]
          allow(Project).to receive(:visible).and_return projects
          allow(projects).to receive(:find_by_id).and_return(stub_project)
        end

        it 'should return nil' do
          expect(controller.work_package).to be_nil

        end
      end
    end

    describe 'when providing neither id nor project_id (error)' do
      it 'should return nil' do
        controller.params = {}

        expect(controller.work_package).to be_nil
      end
    end
  end

  describe '#project' do
    it "should be the work_packages's project" do
      allow(controller).to receive(:work_package).and_return(planning_element)

      expect(controller.project).to eq(planning_element.project)
    end
  end

  describe '#journals' do
    it "should return all the work_package's journals except the first one" do
      planning_element.description = 'blubs'

      planning_element.save
      planning_element.reload

      allow(controller).to receive(:work_package).and_return(planning_element)

      expect(controller.journals).to eq([planning_element.journals.last])
    end

    it 'should be empty if the work_package has only one journal' do
      allow(controller).to receive(:work_package).and_return(planning_element)

      expect(controller.journals).to be_empty
    end

    describe 'order of journal entries' do
      let!(:planning_element_note1) {
        FactoryGirl.create(:work_package_journal,
                           journable_id: planning_element.id,
                           version: 2,
                           notes: 'lala')
      }

      let!(:planning_element_note2) {
        FactoryGirl.create(:work_package_journal,
                           journable_id: planning_element.id,
                           version: 3,
                           notes: 'lala2')
      }

      before do
        allow(controller).to receive(:current_user).and_return(stub_user)
        allow(controller).to receive(:work_package).and_return(planning_element)
      end

      it 'chronological by default' do
        expect(controller.journals).to eq([planning_element_note1, planning_element_note2])
      end

      it "reverse chronological order if the user wan'ts it that way" do
        allow(stub_user).to receive(:wants_comments_in_reverse_order?).and_return(true)
        expect(controller.journals).to eq([planning_element_note2, planning_element_note1])
      end
    end
  end

  describe '#changesets' do
    let(:change1) { double('change_1') }
    let(:change2) { double('change_2') }
    let(:changesets) { [change1, change2] }

    before do
      allow(planning_element).to receive(:changesets).and_return(changesets)
      # couldn't get stub_chain to work
      # https://www.relishapp.com/rspec/rspec-mocks/v/2-0/docs/stubs/stub-a-chain-of-methods
      [:visible, :all, :includes].each do |meth|
        allow(changesets).to receive(meth).and_return(changesets)
      end
      allow(controller).to receive(:work_package).and_return(planning_element)
    end

    it "should have all the work_package's changesets" do
      expect(controller.changesets).to eq(changesets)
    end

    it "should have all the work_package's changesets in reverse order if the user wan'ts it that way" do
      allow(controller).to receive(:current_user).and_return(stub_user)

      allow(stub_user).to receive(:wants_comments_in_reverse_order?).and_return(true)

      expect(controller.changesets).to eq([change2, change1])
    end
  end

  describe '#relations' do
    let(:relation) {
      FactoryGirl.build_stubbed(:relation, from: stub_issue,
                                           to: stub_planning_element)
    }
    let(:relations) { [relation] }

    before do
      allow(controller).to receive(:work_package).and_return(stub_issue)
      allow(stub_issue).to receive(:relations).and_return(relations)
      allow(relations).to receive(:includes).and_return(relations)
    end

    it "should return all the work_packages's relations visible to the user" do
      allow(stub_planning_element).to receive(:visible?).and_return(true)

      expect(controller.relations).to eq(relations)
    end

    it 'should not return relations invisible to the user' do
      allow(stub_planning_element).to receive(:visible?).and_return(false)

      expect(controller.relations).to eq([])
    end
  end

  describe '#ancestors' do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:ancestor_issue) { FactoryGirl.create(:work_package, project: project) }
    let(:issue) { FactoryGirl.create(:work_package, project: project, parent_id: ancestor_issue.id) }

    become_member_with_view_planning_element_permissions

    describe 'when work_package is an issue' do
      let(:ancestor_issue) { FactoryGirl.create(:work_package, project: project) }
      let(:issue) { FactoryGirl.create(:work_package, project: project, parent_id: ancestor_issue.id) }

      it 'should return the work_packages ancestors' do
        allow(controller).to receive(:work_package).and_return(issue)

        expect(controller.ancestors).to eq([ancestor_issue])
      end
    end

    describe 'when work_package is a planning element' do
      let(:descendant_planning_element) {
        FactoryGirl.create(:work_package, project: project,
                                          parent_id: planning_element.id)
      }
      it 'should return the work_packages ancestors' do
        allow(controller).to receive(:work_package).and_return(descendant_planning_element)

        expect(controller.ancestors).to eq([planning_element])
      end
    end
  end

  describe '#descendants' do
    before do
      allow(controller).to receive(:work_package).and_return(planning_element)
    end

    it 'should be empty' do
      expect(controller.descendants).to be_empty
    end
  end

  describe '#priorities' do
    it 'should return all defined priorities' do
      expected = double('priorities')

      allow(IssuePriority).to receive(:active).and_return(expected)

      expect(controller.priorities).to eq(expected)
    end
  end

  describe '#allowed_statuses' do
    it 'should return all statuses allowed by the issue' do
      expected = double('statuses')

      allow(controller).to receive(:work_package).and_return(stub_issue)

      allow(stub_issue).to receive(:new_statuses_allowed_to).with(current_user).and_return(expected)

      expect(controller.allowed_statuses).to eq(expected)
    end
  end

  describe '#time_entry' do
    before do
      allow(controller).to receive(:work_package).and_return(stub_planning_element)
    end

    it 'should return a time entry' do
      expected = double('time_entry')

      allow(stub_planning_element).to receive(:add_time_entry).and_return(expected)

      expect(controller.time_entry).to eq(expected)
    end
  end

  describe 'quotation' do
    let(:call_action) { get :quoted }

    requires_permission_in_project do
      context 'description' do
        subject { get :quoted, id: planning_element.id }

        it { is_expected.to be_success }
        it { is_expected.to render_template('edit') }
      end

      context 'journal' do
        let(:journal_id) { planning_element.journals.first.id }

        subject { get :quoted, id: planning_element.id, journal_id: journal_id }

        it { is_expected.to be_success }
        it { is_expected.to render_template('edit') }
      end
    end
  end

  let(:filename) { 'testfile.txt' }
  let(:file) { File.open(Rails.root.join('spec/fixtures/files', filename)) }
  let(:uploaded_file) { ActionDispatch::Http::UploadedFile.new(tempfile: file, type: 'text/plain', filename: filename) }

  describe '#create' do
    let(:type) { FactoryGirl.create :type }
    let(:project) {
      FactoryGirl.create :project,
                         types: [type]
    }
    let(:status) { FactoryGirl.create :default_status }
    let(:priority) { FactoryGirl.create :priority }

    context 'copy' do
      let(:current_user) { FactoryGirl.create(:admin) }
      let(:params) { { copy_from: planning_element.id, project_id: project.id } }
      let(:except) {
        ['id',
         'root_id',
         'parent_id',
         'lft',
         'rgt',
         'type',
         'created_at',
         'updated_at']
      }

      before { post 'create', params }

      subject { response }

      it do
        expect(assigns['new_work_package']).not_to eq(nil)
        expect(assigns['new_work_package'].attributes.dup.except(*except)).to eq(planning_element.attributes.dup.except(*except))
      end
    end

    context 'attachments' do
      let(:new_work_package) {
        FactoryGirl.build(:work_package,
                          project: project,
                          type: type,
                          description: 'Description',
                          priority: priority)
      }
      let(:params) {
        { project_id: project.id,
          attachments: { '1' => { 'file' => uploaded_file,
                                  'description' => '' } } }
      }

      before do
        allow(controller).to receive(:work_package).and_return(new_work_package)
        expect(controller).to receive(:authorize).and_return(true)

        allow_any_instance_of(Attachment).to receive(:filename).and_return(filename)
        allow_any_instance_of(Attachment).to receive(:copy_file_to_destination)
      end

      # see ticket #2009 on OpenProject.org
      context 'new attachment on new work package' do
        before { post 'create', params }

        describe '#journal' do
          let(:attachment_id) { "attachments_#{new_work_package.attachments.first.id}" }

          subject { new_work_package.journals.last.changed_data }

          it { is_expected.to have_key attachment_id }

          it { expect(subject[attachment_id]).to eq([nil, filename]) }
        end
      end

      context 'invalid attachment' do
        let(:max_filesize) { Setting.attachment_max_size.to_i.kilobytes }

        before do
          allow_any_instance_of(Attachment).to receive(:filesize).and_return(max_filesize + 1)

          post :create, params
        end

        describe '#view' do
          subject { response }

          it { is_expected.to render_template('work_packages/new', formats: ['html']) }
        end

        describe '#error' do
          subject { new_work_package.errors.messages }

          it { is_expected.to have_key(:attachments) }

          it { subject[:attachments] =~ /too long/ }
        end
      end
    end
  end

  describe '#update' do
    let(:type) { FactoryGirl.create :type }
    let(:project) {
      FactoryGirl.create :project,
                         types: [type]
    }
    let(:status) { FactoryGirl.create :default_status }
    let(:priority) { FactoryGirl.create :priority }

    context 'attachments' do
      let(:work_package) {
        FactoryGirl.build(:work_package,
                          project: project,
                          type: type,
                          description: 'Description',
                          priority: priority)
      }
      let(:params) {
        { id: work_package.id,
          work_package: { attachments: { '1' => { 'file' => uploaded_file,
                                                  'description' => '' } } } }
      }

      before do
        allow(controller).to receive(:work_package).and_return(work_package)
        expect(controller).to receive(:authorize).and_return(true)

        expect(current_user).to receive(:allowed_to?).with(:edit_work_packages, project).and_return(true)

        allow_any_instance_of(Attachment).to receive(:filename).and_return(filename)
        allow_any_instance_of(Attachment).to receive(:copy_file_to_destination)
      end

      context 'invalid attachment' do
        let(:max_filesize) { Setting.attachment_max_size.to_i.kilobytes }

        before do
          allow_any_instance_of(Attachment).to receive(:filesize).and_return(max_filesize + 1)

          post :update, params
        end

        describe '#view' do
          subject { response }

          it { is_expected.to render_template('work_packages/edit', formats: ['html']) }
        end

        describe '#error' do
          subject { work_package.errors.messages }

          it { is_expected.to have_key(:attachments) }

          it { subject[:attachments] =~ /too long/ }
        end
      end
    end
  end

  describe 'preview' do
    let(:project) { FactoryGirl.create(:project) }
    let(:role) {
      FactoryGirl.create(:role,
                         permissions: [:add_work_packages])
    }
    let(:user) {
      FactoryGirl.create(:user,
                         member_in_project: project,
                         member_through_role: role)
    }
    let(:description) { 'Work package description' }
    let(:notes) { 'Work package note' }
    let(:preview_params) {
      { work_package: { description: description,
                        journal_notes: notes } }
    }

    before { allow(User).to receive(:current).and_return(user) }

    it_behaves_like 'valid preview' do
      let(:preview_texts) { [description, notes] }
    end

    it_behaves_like 'authorizes object access' do
      let(:work_package) { FactoryGirl.create(:work_package) }
      let(:preview_params) {
        { id: work_package.id,
          work_package: {} }
      }
    end

    describe 'preview.js' do
      before { xhr :put, :preview, preview_params }

      it {
        expect(response).to render_template('common/preview',
                                            format: ['html'],
                                            layout: false)
      }
    end
  end

  describe 'Update permissions' do
    let(:project) { FactoryGirl.create(:project) }

    let(:description) { 'Muh hahahah!!!' }
    let(:notes) { 'Work package note' }
    let(:wp_params) {
      { id: work_package.id,
        work_package: { description: description,
                        journal_notes: notes } }
    }

    shared_context 'update work package' do
      let(:user) {
        FactoryGirl.create(:user,
                           member_in_project: project,
                           member_through_role: role)
      }
      let!(:work_package) {
        FactoryGirl.create(:work_package,
                           project_id: project.id,
                           author: user)
      }
      let!(:original_description) { work_package.description }

      before do
        allow(User).to receive(:current).and_return user

        put 'update', wp_params

        work_package.reload
      end
    end

    describe '#14964 User w/o permission able to update work package attributes' do
      let(:role) {
        FactoryGirl.create(:role,
                           permissions: [:view_work_packages,
                                         :add_work_package_notes])
      }

      include_context 'update work package'

      it { expect(work_package.description).to eq(original_description) }

      it { expect(work_package.journals.last.notes).to eq(notes) }
    end

    describe 'notes update w/o privileges' do
      let(:role) {
        FactoryGirl.create(:role,
                           permissions: [:view_work_packages,
                                         :edit_work_packages])
      }

      include_context 'update work package'

      it { expect(work_package.description).to eq(description) }

      it { expect(work_package.journals.last.notes).to be_empty }
    end
  end
end
