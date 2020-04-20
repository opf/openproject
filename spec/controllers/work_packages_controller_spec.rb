#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackagesController, type: :controller do
  before do
    login_as current_user
  end

  let(:project) { FactoryBot.create(:project, identifier: 'test_project', public: false) }
  let(:stub_project) { FactoryBot.build_stubbed(:project, identifier: 'test_project', public: false) }
  let(:type) { FactoryBot.build_stubbed(:type) }
  let(:stub_work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             id: 1337,
                             type: type,
                             project: stub_project)
  end

  let(:current_user) { FactoryBot.create(:user) }

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
    let(:query) { FactoryBot.build_stubbed(:query).tap(&:add_default_filter) }
    let(:work_packages) { double('work packages').as_null_object }
    let(:results) { double('results').as_null_object }

    describe 'with valid query' do
      before do
        allow(User.current).to receive(:allowed_to?).and_return(false)
        expect(User.current).to receive(:allowed_to?)
                                  .with({ controller: 'work_packages',
                                          action: 'index' },
                                        project,
                                        global: project.nil?)
                                  .and_return(true)

        allow(controller).to receive(:retrieve_query).and_return(query)
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

      shared_examples_for 'export of mime_type' do
        let(:export_storage) { FactoryBot.build_stubbed(:work_packages_export) }
        let(:call_action) { get('index', params: params.merge(format: mime_type)) }

        requires_export_permission do
          before do
            service_instance = double('service_instance')

            allow(WorkPackages::Exports::ScheduleService)
              .to receive(:new)
              .with(user: current_user)
              .and_return(service_instance)

            allow(service_instance)
              .to receive(:call)
              .with(query: query, mime_type: mime_type.to_sym, params: anything)
              .and_return(ServiceResult.new(result: export_storage))
          end

          it 'should fulfill the defined should_receives' do
            call_action

            expect(response)
              .to redirect_to(work_packages_export_path(export_storage.id))
          end
        end
      end

      describe 'csv' do
        let(:params) { {} }
        let(:mime_type) { 'csv' }

        it_behaves_like 'export of mime_type'
      end

      describe 'pdf' do
        let(:params) { {} }
        let(:mime_type) { 'pdf' }

        it_behaves_like 'export of mime_type' do
        end
      end

      describe 'atom' do
        let(:params) { {} }
        let(:call_action) { get('index', params: params.merge(format: 'atom')) }

        requires_export_permission do
          before do
            # Note: Stubs for methods used to build up the json query results.
            # TODO RS:  Clearly this isn't testing anything, but it all needs to be moved to an API controller anyway.
            allow(query).to receive(:results).and_return(results)
            allow(results).to receive_message_chain(:sorted_work_packages, :page, :per_page).and_return(work_packages)

            expect(controller).to receive(:render_feed).with(work_packages, anything) do |*_args|
              # We need to render something because otherwise
              # the controller will and it will not find a suitable template
              controller.render plain: 'success'
            end
          end

          it 'should fulfill the defined should_receives' do
            call_action
          end
        end
      end
    end

    context 'with invalid query' do
      describe 'pdf' do
        let(:call_action) { get('index', params: params.merge(format: 'pdf')) }
        let(:params) { { query_id: 'hokusbogus' } }

        context 'when a non-existant query has been previously selected' do
          before do
            allow(User.current).to receive(:allowed_to?).and_return(true)

            allow(controller)
              .to receive(:retrieve_query)
              .and_raise(ActiveRecord::RecordNotFound)

            call_action
          end

          it 'renders a 404' do
            expect(response.response_code).to eql 404
          end
        end
      end
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

        expect(WorkPackage::Exporter::PDF).to receive(:single).and_yield(pdf_result)
        expect(controller).to receive(:send_data).with(pdf_data,
                                                       type: expected_type,
                                                       filename: expected_name) do |*_args|
          # We need to render something because otherwise
          # the controller will and it will not find a suitable template
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
