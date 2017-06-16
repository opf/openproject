#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

  let(:project) { FactoryGirl.create(:project, identifier: 'test_project', is_public: false) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project, identifier: 'test_project', is_public: false) }
  let(:stub_work_package) { double('work_package', id: 1337, project: stub_project).as_null_object }

  let(:current_user) { FactoryGirl.create(:user) }

  def self.requires_permission_in_project(&block)
    describe 'w/o the permission to see the project/work_package' do
      before do
        allow(controller).to receive(:work_package).and_return(nil)

        call_action
      end

      it 'should render a 403' do
        expect(response.response_code).to be === 403
      end
    end

    describe 'w/ the permission to see the project
              w/ having the necessary permissions' do
      before do
        expect(WorkPackage).to receive_message_chain('visible.find_by').and_return(stub_work_package)
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
    let(:results) { double('results').as_null_object }

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
        allow(controller).to receive(:retrieve_query_v3).and_return(query)

        # Note: Stubs for methods used to build up the json query results.
        # TODO RS:  Clearly this isn't testing anything, but it all needs to be moved to an API controller anyway.
        allow(query).to receive(:results).and_return(results)
        allow(results).to receive_message_chain(:sorted_work_packages, :page, :per_page).and_return(work_packages)
      end

      describe 'html' do
        let(:call_action) { get('index', params: { project_id: project.id }) }
        before do
          call_action
        end

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
      end

      describe 'csv' do
        let(:params) { {} }
        let(:call_action) { get('index', params: params.merge(format: 'csv')) }

        requires_export_permission do
          before do
            mock_result = double('mock csv result',
                                 error?: false,
                                 content: 'blubs',
                                 mime_type: 'text/csv',
                                 title: 'blubs.csv')

            mock_csv = double('csv exporter',
                              list: mock_result)

            expect(WorkPackage::Exporter::CSV)
              .to receive(:new)
              .with(query, anything)
              .and_return(mock_csv)

            expect(controller)
              .to receive(:send_data)
              .with(mock_result.content,
                    type: mock_result.mime_type,
                    filename: mock_result.title) do |_|
              # We need to render something because otherwise
              # the controller will and he will not find a suitable template
              controller.render plain: 'success'
            end
          end

          it 'should fulfill the defined should_receives' do
            call_action
          end
        end
      end

      describe 'pdf' do
        let(:params) { {} }
        let(:call_action) { get('index', params: params.merge(format: 'pdf')) }

        requires_export_permission do
          context 'w/ a valid query' do
            before do
              mock_result = double('mock pdf result',
                                   error?: false,
                                   content: 'blubs',
                                   mime_type: 'application/pdf',
                                   title: 'blubs.pdf')

              mock_pdf = double('pdf exporter',
                                list: mock_result)

              expect(WorkPackage::Exporter::PDF)
                .to receive(:new)
                .with(query, anything)
                .and_return(mock_pdf)

              expect(controller)
                .to receive(:send_data)
                .with(mock_result.content,
                      type: mock_result.mime_type,
                      filename: mock_result.title) do |_|
                # We need to render something because otherwise
                # the controller will and he will not find a suitable template
                controller.render plain: 'success'
              end
            end

            it 'should fulfill the defined should_receives' do
              call_action
            end
          end

          context 'with invalid query' do
            let(:params) { { query_id: 'hokusbogus' } }

            context 'when a non-existant query has been previously selected' do
              before do
                allow(controller)
                  .to receive(:retrieve_query_v3)
                  .and_raise(ActiveRecord::RecordNotFound)

                call_action
              end

              it 'renders a 404' do
                expect(response.response_code).to be === 404
              end
            end
          end

          context 'with an export error' do
            before do
              mock_result = double('mock pdf result',
                                   error?: true,
                                   message: 'because')

              mock_pdf = double('pdf exporter',
                                list: mock_result)

              allow(WorkPackage::Exporter::PDF)
                .to receive(:new)
                .with(query, anything)
                .and_return(mock_pdf)

              call_action
            end

            it "shows the error message" do
              expect(flash[:error].downcase).to include("because")
            end

            it "redirects to the html index" do
              if project
                expect(response).to redirect_to project_work_packages_path(project)
              else
                expect(response).to redirect_to work_packages_path
              end
            end
          end
        end
      end

      describe 'atom' do
        let(:params) { {} }
        let(:call_action) { get('index', params: params.merge(format: 'atom')) }

        requires_export_permission do
          before do
            expect(controller).to receive(:render_feed).with(work_packages, anything) do |*_args|
              # We need to render something because otherwise
              # the controller will and he will not find a suitable template
              controller.render plain: 'success'
            end
          end

          it 'should fulfill the defined should_receives' do
            call_action
          end
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
        description: "\u2022 requires unicode.",
        assigned_to: current_user
      )
    end
    let(:current_user) { FactoryGirl.create(:admin) }

    it 'performs a successful export' do
      wp = work_package

      expect do
        get :index, params: { format: 'csv', c: [:subject, :assignee, :updatedAt] }
      end.not_to raise_error

      data = CSV.parse(response.body)

      expect(data.size).to eq(2)
      expect(data.last).to include(wp.subject)
      expect(data.last).to include(wp.description)
      expect(data.last).to include(current_user.name)
      expect(data.last).to include(wp.updated_at.localtime.strftime("%m/%d/%Y %I:%M %p"))
    end
  end

  describe 'index with a broken project reference' do
    before do
      get('index', params: { project_id: 'project_that_doesnt_exist' })
    end

    it { is_expected.to respond_with :not_found }
  end

  describe 'show.html' do
    let(:call_action) { get('show', params: { id: '1337' }) }

    requires_permission_in_project do
      it 'renders the show builder template' do
        call_action

        expect(response).to render_template('work_packages/show')
      end
    end
  end

  describe 'show.pdf' do
    let(:call_action) { get('show', params: { format: 'pdf', id: '1337' }) }

    requires_permission_in_project do
      it 'respond with a pdf' do
        pdf_data = 'foobar'
        expected_name = "#{stub_work_package.project.identifier}-#{stub_work_package.id}.pdf"
        expected_type = 'application/pdf'
        pdf_result = double('pdf_result',
                            error?: false,
                            content: pdf_data,
                            title: expected_name,
                            mime_type: expected_type)

        expect(WorkPackage::Exporter::PDF).to receive(:single).and_return(pdf_result)
        expect(controller).to receive(:send_data).with(pdf_data,
                                                       type: expected_type,
                                                       filename: expected_name) do |*_args|
          # We need to render something because otherwise
          # the controller will and he will not find a suitable template
          controller.render plain: 'success'
        end
        call_action
      end
    end
  end

  describe 'show.atom' do
    let(:call_action) { get('show', params: { format: 'atom', id: '1337' }) }

    requires_permission_in_project do
      it 'render the journal/index template' do
        call_action

        expect(response).to render_template('journals/index')
      end
    end
  end

  describe 'redirect deep link', with_settings: { login_required?: true } do
    let(:current_user) { User.anonymous }
    let(:params) do
      { project_id: project.id }
    end

    it 'redirects to collection with query' do
      get 'index', params: params.merge(query_id: 123, query_props: 'foo')
      expect(response).to be_redirect

      location = "/projects/#{project.id}/work_packages?query_id=123&query_props=foo"
      expect(response.location).to end_with(CGI.escape(location))
    end
  end
end
