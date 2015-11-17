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
        allow(query).to receive_message_chain(:results, :work_packages, :page, :per_page).and_return(work_packages)
        allow(query).to receive_message_chain(:results, :work_package_count_by_group).and_return([])
        allow(query).to receive_message_chain(:results, :column_total_sums).and_return([])
        allow(query).to receive_message_chain(:results, :column_group_sums).and_return([])
        allow(query).to receive(:as_json).and_return('')
      end

      describe 'html' do
        let(:call_action) { get('index', project_id: project.id) }
        before do call_action end

        describe 'w/o a project' do
          let(:project) { nil }
          let(:call_action) { get('index') }

          it 'should render the index template' do
            expect(response).to render_template('work_packages/index')
          end
        end

        context 'w/ a project' do
          it 'should render the index template' do
            expect(response).to render_template('work_packages/index')
          end
        end

        context 'when a query has been previously selected' do
          let(:query) do
            FactoryGirl.build_stubbed(:query).tap { |q| q.filters = [Queries::WorkPackages::Filter.new('done_ratio', operator: '>=', values: [10])] }
          end

          before do allow(session).to receive(:query).and_return query end

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
        before do call_action end

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
    before do get('index', project_id: 'project_that_doesnt_exist') end

    it { is_expected.to respond_with :not_found }
  end

  describe 'show.html' do
    let(:call_action) { get('show', id: '1337') }

    requires_permission_in_project do
      it 'renders the show builder template' do
        call_action

        expect(response).to render_template('work_packages/show')
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

        expect(response).to render_template('journals/index')
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

      describe 'if the project is not visible for the current_user' do
        before do
          projects = [stub_project]
          allow(Project).to receive(:visible).and_return projects
          allow(projects).to receive(:find_by).and_return(stub_project)
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

  let(:filename) { 'testfile.txt' }
  let(:file) { File.open(Rails.root.join('spec/fixtures/files', filename)) }
  let(:uploaded_file) { ActionDispatch::Http::UploadedFile.new(tempfile: file, type: 'text/plain', filename: filename) }
end
