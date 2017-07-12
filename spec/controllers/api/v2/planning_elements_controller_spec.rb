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

describe Api::V2::PlanningElementsController, type: :controller do
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
        current_user.memberships.select { |m| m.project_id == p.id }.each(&:destroy)
      end
    end
  end

  def self.become_member_with_view_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, permissions: [:view_work_packages])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        member = FactoryGirl.build(:member, user: current_user, project: p)
        member.roles = [role]
        member.save!
      end
    end
  end

  def self.become_member_with_edit_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, permissions: [:edit_work_packages])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |p|
        member = FactoryGirl.build(:member, user: current_user, project: p)
        member.roles = [role]
        member.save!
      end
    end
  end

  def self.become_member_with_delete_planning_element_permissions(&block)
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, permissions: [:delete_work_packages])

      projects = block ? instance_eval(&block) : [project]

      projects.each do |_p|
        member = FactoryGirl.build(:member, user: current_user, project: project)
        member.roles = [role]
        member.save!
      end
    end
  end

  def work_packages_to_structs(work_packages)
    work_packages.map do |model|
      Struct::WorkPackage.new.tap do |s|
        model.attributes.each do |attribute, value|
          s.send(:"#{attribute}=", value)
        end
        s.child_ids = []
        s.custom_values = []
      end
    end
  end

  before do
    allow(User).to receive(:current).and_return current_user

    FactoryGirl.create :priority, is_default: true
    FactoryGirl.create :default_status
  end

  # ===========================================================
  # API tests

  describe 'index.xml' do
    become_admin

    describe 'w/ list of ids' do
      describe 'w/ an unknown work package id' do
        it 'renders an empty list' do
          get 'index', params: { ids: '4711' }, format: 'xml'

          expect(assigns(:planning_elements)).to eq([])
        end
      end

      describe 'w/ known work package ids in one project' do
        let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }
        let(:work_package) { FactoryGirl.create(:work_package, project_id: project.id) }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders an empty list' do
            get 'index', params: { ids: work_package.id.to_s }, format: 'xml'

            expect(assigns(:planning_elements)).to eq([])
          end
        end

        describe 'w/ the current user being a member with view_work_packages permissions' do
          become_member_with_view_planning_element_permissions

          before do
            get 'index', params: { ids: '' }, format: 'xml'
          end

          describe 'w/o any planning elements within the project' do
            it 'assigns an empty planning_elements array' do
              expect(assigns(:planning_elements)).to eq([])
            end

            it 'renders the index builder template' do
              expect(response).to render_template('planning_elements/index')
            end
          end

          describe 'w/ 3 planning elements within the project' do
            before do
              @created_planning_elements = [
                FactoryGirl.create(:work_package, project_id: project.id),
                FactoryGirl.create(:work_package, project_id: project.id),
                FactoryGirl.create(:work_package, project_id: project.id)
              ]
              get 'index',
                  params: { ids: @created_planning_elements.map(&:id).join(',') },
                  format: 'xml'
            end

            it 'assigns a planning_elements array containing all three elements' do
              expect(assigns(:planning_elements)).to match_array(@created_planning_elements)
            end

            it 'renders the index builder template' do
              expect(response).to render_template('planning_elements/index')
            end
          end

          describe 'w/ 2 planning elements within a specific project and one PE requested' do
            context 'with rewire_parents=false' do
              let!(:wp_parent) { FactoryGirl.create(:work_package, project_id: project.id) }
              let!(:wp_child)  {
                FactoryGirl.create(:work_package, project_id: project.id,
                                                  parent_id: wp_parent.id)
              }

              context 'with rewire_parents=false' do
                before do
                  get 'index',
                      params: {
                        project_id: project.id,
                        ids: wp_child.id.to_s,
                        rewire_parents: 'false'
                      },
                      format: 'xml'
                end

                it "includes the child's parent_id" do
                  expect(assigns(:planning_elements)[0].parent_id).to eq wp_parent.id
                end
              end

              context 'without rewire_parents' do
                # This is unbelievably inconsistent. When requesting this without a project_id,
                # the rewiring is not done at all, so the parent_id can be seen with and
                # without rewiring disabled.
                # Passing a project_id here, so we can test this with rewiring enabled.
                before do
                  get 'index',
                      params: {
                        project_id: project.id,
                        ids: wp_child.id.to_s
                      },
                      format: 'xml'
                end

                it "doesn't include child's parent_id" do
                  expect(assigns(:planning_elements)[0].parent_id).to eq nil
                end
              end
            end
          end
        end
      end

      describe 'w/ known work package ids in multiple projects' do
        let(:project_a) { FactoryGirl.create(:project, identifier: 'project_a') }
        let(:project_b) { FactoryGirl.create(:project, identifier: 'project_b') }
        let(:project_c) { FactoryGirl.create(:project, identifier: 'project_c') }
        before do
          @project_a_wps = [
            FactoryGirl.create(:work_package, project_id: project_a.id),
            FactoryGirl.create(:work_package, project_id: project_a.id),
          ]
          @project_b_wps = [
            FactoryGirl.create(:work_package, project_id: project_b.id),
            FactoryGirl.create(:work_package, project_id: project_b.id),
          ]
          @project_c_wps = [
            FactoryGirl.create(:work_package, project_id: project_c.id),
            FactoryGirl.create(:work_package, project_id: project_c.id)
          ]
        end

        describe 'w/ an unknown pe in the list' do
          become_admin { [project_a, project_b] }

          it 'renders only existing work packages' do
            get 'index',
                params: {
                  ids: [@project_a_wps[0].id, @project_b_wps[0].id, '4171', '5555'].join(',')
                },
                format: 'xml'

            expect(assigns(:planning_elements)).to match_array([@project_a_wps[0], @project_b_wps[0]])
          end
        end

        describe 'w/ an inaccessible pe in the list' do
          become_member_with_view_planning_element_permissions { [project_a, project_b] }
          become_non_member { [project_c] }

          it 'renders only accessible work packages' do
            get 'index',
                params: {
                  ids: [@project_a_wps[0].id, @project_b_wps[0].id,
                        @project_c_wps[0].id, @project_c_wps[1].id].join(',')
                },
                format: 'xml'

            expect(assigns(:planning_elements)).to match_array([@project_a_wps[0], @project_b_wps[0]])
          end

          it 'renders only accessible work packages' do
            get 'index',
                params: { ids: [@project_c_wps[0].id, @project_c_wps[1].id].join(',') },
                format: 'xml'

            expect(assigns(:planning_elements)).to match_array([])
          end
        end

        describe 'w/ multiple work packages in multiple projects' do
          become_member_with_view_planning_element_permissions { [project_a, project_b, project_c] }

          it 'renders all work packages' do
            get 'index',
                params: {
                  ids: (@project_a_wps + @project_b_wps + @project_c_wps).map(&:id).join(',')
                },
                format: 'xml'

            expect(assigns(:planning_elements)).to match_array(@project_a_wps + @project_b_wps + @project_c_wps)
          end
        end
      end

      describe 'w/ cross-project relations' do
        before do
          allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
        end

        let!(:project1) { FactoryGirl.create(:project, identifier: 'project-1') }
        let!(:project2) { FactoryGirl.create(:project, identifier: 'project-2') }
        let!(:ticket_a) { FactoryGirl.create(:work_package, project_id: project1.id) }
        let!(:ticket_b) { FactoryGirl.create(:work_package, project_id: project1.id, parent_id: ticket_a.id) }
        let!(:ticket_c) { FactoryGirl.create(:work_package, project_id: project1.id, parent_id: ticket_b.id) }
        let!(:ticket_d) { FactoryGirl.create(:work_package, project_id: project1.id) }
        let!(:ticket_e) { FactoryGirl.create(:work_package, project_id: project2.id, parent_id: ticket_d.id) }
        let!(:ticket_f) { FactoryGirl.create(:work_package, project_id: project1.id, parent_id: ticket_e.id) }

        become_admin { [project1, project2] }

        context 'without rewire_parents' do  # equivalent to rewire_parents=true
          it 'rewires ancestors correctly' do
            get 'index',
                params: { project_id: project1.id },
                format: 'xml'

            # the controller returns structs. We therefore have to filter for those
            ticket_f_struct = assigns(:planning_elements).detect { |pe| pe.id == ticket_f.id }

            expect(ticket_f_struct.parent_id).to eq(ticket_d.id)
          end
        end

        context 'with rewire_parents=false' do
          before do
            get 'index',
                params: { project_id: project1.id, rewire_parents: 'false' },
                format: 'xml'
          end

          it "doesn't rewire ancestors" do
            # the controller returns structs. We therefore have to filter for those
            ticket_f_struct = assigns(:planning_elements).detect { |pe| pe.id == ticket_f.id }

            expect(ticket_f_struct.parent_id).to eq(ticket_e.id)
          end

          it 'filters out invisible work packages' do
            expect(assigns(:planning_elements).map(&:id)).not_to include(ticket_e.id)
          end
        end
      end

      describe 'changed since' do
        let!(:work_package) do
          work_package = Timecop.travel(5.hours.ago) do
            wp = FactoryGirl.create(:work_package)
            wp.save!
            wp
          end

          work_package.subject = 'Changed now!'
          work_package.save!
          work_package
        end

        become_admin { [work_package.project] }

        shared_context 'get work packages changed since' do
          before do
            get 'index',
                params: { project_id: work_package.project_id, changed_since: timestamp },
                format: 'xml'
          end
        end

        describe 'valid timestamp' do
          shared_examples_for 'valid timestamp' do
            let(:timestamp) { (work_package.updated_at - 5.seconds).to_i }

            include_context 'get work packages changed since'

            it { expect(assigns(:planning_elements).map(&:id)).to match_array([work_package.id]) }
          end

          shared_examples_for 'valid but early timestamp' do
            let(:timestamp) { (work_package.updated_at + 5.seconds).to_i }

            include_context 'get work packages changed since'

            it { expect(assigns(:planning_elements)).to be_empty }
          end

          it_behaves_like 'valid timestamp'

          it_behaves_like 'valid but early timestamp'
        end

        describe 'invalid timestamp' do
          let(:timestamp) { 'eeek' }

          include_context 'get work packages changed since'

          it { expect(response.status).to eq(400) }
        end
      end
    end

    describe 'ids' do
      let(:project_a) { FactoryGirl.create(:project) }
      let(:project_b) { FactoryGirl.create(:project) }
      let(:project_c) { FactoryGirl.create(:project) }
      let!(:work_package_a) {
        FactoryGirl.create(:work_package,
                           project: project_a)
      }
      let!(:work_package_b) {
        FactoryGirl.create(:work_package,
                           project: project_b)
      }
      let!(:work_package_c) {
        FactoryGirl.create(:work_package,
                           project: project_c)
      }
      let(:project_ids) { [project_a, project_b, project_c].map(&:id).join(',') }
      let(:wp_ids) { [work_package_a, work_package_b].map(&:id) }

      become_admin { [project_a, project_b, work_package_c.project] }

      describe 'empty ids' do
        before do
          get 'index',
              params: { project_id: project_ids, ids: '' },
              format: 'xml'
        end

        it { expect(assigns(:planning_elements)).to be_empty }
      end

      shared_examples_for 'valid ids request' do
        before do
          get 'index',
              params: { project_id: project_ids, ids: wp_ids.join(',') },
              format: 'xml'
        end

        subject { assigns(:planning_elements).map(&:id) }

        it { expect(subject).to include(*wp_ids) }

        it { expect(subject).not_to include(*invalid_wp_ids) }
      end

      describe 'known ids' do
        context 'single id' do
          it_behaves_like 'valid ids request' do
            let(:wp_ids) { [work_package_a.id] }
            let(:invalid_wp_ids) { [work_package_b.id, work_package_c.id] }
          end
        end

        context 'multiple ids' do
          it_behaves_like 'valid ids request' do
            let(:wp_ids) { [work_package_a.id, work_package_b.id] }
            let(:invalid_wp_ids) { [work_package_c.id] }
          end
        end
      end
    end

    describe 'w/ list of projects' do
      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'index', params: { project_id: 'project_x,project_b' }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'index', params: { project_id: project.identifier }, format: 'xml'

            expect(response.response_code).to eq(403)
          end
        end

        describe 'w/ the current user being a member with view_work_packages permissions' do
          become_member_with_view_planning_element_permissions

          before do
            get 'index', params: { project_id: project.id }, format: 'xml'
          end

          describe 'w/o any planning elements within the project' do
            it 'assigns an empty planning_elements array' do
              expect(assigns(:planning_elements)).to eq([])
            end

            it 'renders the index builder template' do
              expect(response).to render_template('planning_elements/index')
            end
          end

          describe 'w/ 3 planning elements within the project' do
            before do
              created_planning_elements = [
                FactoryGirl.create(:work_package, project_id: project.id),
                FactoryGirl.create(:work_package, project_id: project.id),
                FactoryGirl.create(:work_package, project_id: project.id)
              ]
              @created_planning_elements = work_packages_to_structs(created_planning_elements)

              get 'index', params: { project_id: project.id }, format: 'xml'
            end

            it 'assigns a planning_elements array containing all three elements' do
              expect(assigns(:planning_elements)).to match_array(@created_planning_elements)
            end

            it 'renders the index builder template' do
              expect(response).to render_template('planning_elements/index')
            end
          end
        end
      end

      describe 'w/ multiple known projects' do
        let(:project_a) { FactoryGirl.create(:project, identifier: 'project_a') }
        let(:project_b) { FactoryGirl.create(:project, identifier: 'project_b') }
        let(:project_c) { FactoryGirl.create(:project, identifier: 'project_c') }

        describe 'w/ an unknown project in the list' do
          become_admin { [project_a, project_b] }

          it 'renders a 404 Not Found page' do
            get 'index', params: { project_id: 'project_x,project_b' }, format: 'xml'
            expect(response.response_code).to eq(404)
          end
        end

        describe 'w/ a project in the list, the current user may not access' do
          before { project_a; project_b }
          become_non_member { [project_b] }
          before do
            get 'index', params: { project_id: 'project_a,project_b' }, format: 'xml'
          end

          it 'assigns an empty planning_elements array' do
            expect(assigns(:planning_elements)).to eq([])
          end

          it 'renders the index builder template' do
            expect(response).to render_template('planning_elements/index')
          end
        end

        describe 'w/ the current user being a member with view_work_packages permission' do
          become_member_with_view_planning_element_permissions { [project_a, project_b] }

          before do
            get 'index', params: { project_id: 'project_a,project_b' }, format: 'xml'
          end

          describe 'w/o any planning elements within the project' do
            it 'assigns an empty planning_elements array' do
              expect(assigns(:planning_elements)).to eq([])
            end

            it 'renders the index builder template' do
              expect(response).to render_template('planning_elements/index')
            end
          end

          describe 'w/ 1 planning element in project_a and 2 in project_b' do
            before do
              created_planning_elements = [
                FactoryGirl.create(:work_package, project_id: project_a.id),
                FactoryGirl.create(:work_package, project_id: project_b.id),
                FactoryGirl.create(:work_package, project_id: project_b.id)
              ]

              @created_planning_elements = work_packages_to_structs(created_planning_elements)

              # adding another planning element, just to make sure, that the
              # result set is properly filtered
              FactoryGirl.create(:work_package, project_id: project_c.id)
              get 'index', params: { project_id: 'project_a,project_b' }, format: 'xml'
            end

            it 'assigns a planning_elements array containing all three elements' do
              expect(assigns(:planning_elements)).to match_array(@created_planning_elements)
            end

            it 'renders the index builder template' do
              expect(response).to render_template('planning_elements/index')
            end
          end
        end
      end
    end
  end

  describe 'create.xml' do
    let(:project) { FactoryGirl.create(:project_with_types, is_public: false) }
    let(:author)  { FactoryGirl.create(:user) }

    become_admin

    describe 'permissions' do
      let(:planning_element) do
        FactoryGirl.build(:work_package, author: author, project_id: project.id)
      end

      def fetch
        post 'create',
             params: {
               project_id: project.identifier,
               planning_element: planning_element.attributes
             },
             format: 'xml'
      end

      def expect_redirect_to
        Regexp.new(api_v2_project_planning_elements_path(project))
      end
      let(:permission) { :edit_work_packages }

      it_should_behave_like 'a controller action which needs project permissions'
    end

    describe 'with custom fields' do
      let(:type) { ::Type.find_by(name: 'None') || FactoryGirl.create(:type_standard) }

      let(:custom_field) do
        FactoryGirl.create :issue_custom_field,
                           name: 'Verse',
                           field_format: 'text',
                           projects: [project],
                           types: [type]
      end

      let(:planning_element) do
        FactoryGirl.build(
          :work_package,
          author: author,
          type: type,
          project: project)
      end

      it 'creates a new planning element with the given custom field value' do
        post 'create',
             params: {
               project_id: project.identifier,
               planning_element: planning_element.attributes.merge(
                 custom_fields: [{ id: custom_field.id, value: 'Wurst' }]
               )
             },
             format: 'xml'
        expect(response.response_code).to eq(303)

        id = response.headers['Location'].scan(/\d+/).last.to_i

        wp = WorkPackage.find_by id: id
        expect(wp).not_to be_nil

        custom_value = wp.custom_values.find do |value|
          value.custom_field.name == custom_field.name
        end

        expect(custom_value).not_to be_nil
        expect(custom_value.value).to eq('Wurst')
      end
    end
  end

  describe 'show.xml' do
    become_admin

    describe 'w/o a valid planning element id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', params: { id: '4711' }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'show', params: {  project_id: '4711', id: '1337' }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'show', params: { project_id: project.id, id: '1337' }, format: 'xml'

            expect(response.response_code).to be === 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_view_planning_element_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            expect {
              get 'show', params: {  project_id: project.id, id: '1337' }, format: 'xml'
            }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }
      let(:planning_element) { FactoryGirl.create(:work_package, project_id: project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', params: { id: planning_element.id }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'show', params: { project_id: project.id, id: planning_element.id }, format: 'xml'

            expect(response.response_code).to eq(403)
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_view_planning_element_permissions

          it 'assigns the planning_element' do
            get 'show', params: {  project_id: project.id, id: planning_element.id }, format: 'xml'
            expect(assigns(:planning_element)).to eq(planning_element)
          end

          it 'renders the show builder template' do
            get 'show', params: {  project_id: project.id, id: planning_element.id }, format: 'xml'
            expect(response).to render_template('planning_elements/show')
          end
        end
      end
    end

    describe 'with custom fields' do
      render_views

      let(:project) { FactoryGirl.create(:project) }
      let(:type) { ::Type.find_by(name: 'None') || FactoryGirl.create(:type_standard) }

      let(:custom_field) do
        FactoryGirl.create :text_issue_custom_field,
                           projects: [project],
                           types: [type]
      end

      let(:planning_element) do
        FactoryGirl.create :work_package,
                           type: type,
                           project: project,
                           custom_values: [
                             CustomValue.new(custom_field: custom_field, value: 'Mett')]
      end

      it 'should render the custom field values' do
        get 'show',
            params: { project_id: project.identifier, id: planning_element.id },
            format: 'json'

        expect(response).to be_success
        expect(response.header['Content-Type']).to include 'application/json'
        expect(response.body).to include 'Mett'
      end
    end
  end

  describe 'update.xml' do
    let(:project) { FactoryGirl.create(:project, is_public: false) }
    let(:work_package) { FactoryGirl.create(:work_package) }

    become_admin

    describe 'permissions' do
      let(:planning_element) {
        FactoryGirl.create(:work_package,
                           project_id: project.id)
      }

      def fetch
        post 'update',
             params: {
               project_id: project.identifier,
               id: planning_element.id,
               planning_element: { name: 'blubs' }
             },
             format: 'xml'
      end

      def expect_no_content
        true
      end
      let(:permission) { :edit_work_packages }
      it_should_behave_like 'a controller action which needs project permissions'
    end

    describe 'empty' do
      before do
        put :update,
            params: {
              project_id: work_package.project_id,
              id: work_package.id
            },
            format: :xml
      end

      it { expect(response.status).to eq(400) }
    end

    describe 'notes' do
      let(:note) { 'A note set by API' }

      before do
        put :update,
            params: {
              project_id: work_package.project_id,
              id: work_package.id,
              planning_element: { note: note }
            },
            format: :xml
      end

      it { expect(response.status).to eq(204) }

      describe 'journals' do
        subject { work_package.reload.journals }

        it { expect(subject.count).to eq(2) }

        it { expect(subject.last.notes).to eq(note) }

        it { expect(subject.last.user).to eq(User.current) }
      end
    end

    describe 'with custom fields' do
      let(:type) { ::Type.find_by(name: 'None') || FactoryGirl.create(:type_standard) }

      let(:custom_field) do
        FactoryGirl.create :text_issue_custom_field,
                           projects: [project],
                           types: [type]
      end

      let(:planning_element) do
        FactoryGirl.create :work_package,
                           type: type,
                           project: project,
                           custom_values: [
                             CustomValue.new(custom_field: custom_field, value: 'Mett')]
      end

      it 'updates the custom field value' do
        put 'update',
            params: {
              project_id: project.identifier,
              id: planning_element.id,
              planning_element: {
                custom_fields: [
                  { id: custom_field.id, value: 'Wurst' }
                ]
              }
            },
            format: :xml
        expect(response.response_code).to eq(204)

        wp = WorkPackage.find planning_element.id
        custom_value = wp.custom_values.find do |value|
          value.custom_field.name == custom_field.name
        end

        expect(custom_value).not_to be_nil
        expect(custom_value.value).not_to eq('Mett')
        expect(custom_value.value).to eq('Wurst')
      end
    end

    describe 'with list custom fields' do
      let(:type) { ::Type.find_by(name: 'None') || FactoryGirl.create(:type_standard) }

      let(:custom_field) do
        FactoryGirl.create :list_wp_custom_field,
                           projects: [project],
                           types: [type],
                           possible_values: ['foo', 'bar', 'baz']
      end

      let(:planning_element) do
        FactoryGirl.create :work_package,
                           type: type,
                           project: project,
                           custom_values: [
                             CustomValue.new(
                               custom_field: custom_field,
                               value: custom_field.possible_values.first.id
                             )
                           ]
      end

      it 'updates the custom field value' do
        put 'update',
            params: {
              project_id: project.identifier,
              id: planning_element.id,
              planning_element: {
                custom_fields: [
                  { id: custom_field.id, value: 'bar' }
                ]
              }
            },
            format: :xml
        expect(response.response_code).to eq(204)

        wp = WorkPackage.find planning_element.id
        custom_value = wp.custom_values.find do |value|
          value.custom_field.name == custom_field.name
        end

        expect(custom_value).not_to be_nil
        expect(custom_value.value).not_to eq(custom_field.possible_values.first.id.to_s)
        expect(custom_value.value).to eq(custom_field.possible_values.second.id.to_s)
      end
    end

    ##
    # It should be possible to update a planning element's status by transmitting the
    # field 'status_id'. The test tries to change a planning element's status from
    # status A to B.
    describe 'status' do
      let(:status_a) { FactoryGirl.create :status }
      let(:status_b) { FactoryGirl.create :status }
      let(:planning_element) { FactoryGirl.create :work_package, status: status_a }

      shared_examples_for 'work package status change' do
        before do
          put 'update',
              params: {
                project_id: project.identifier,
                id: planning_element.id,
                planning_element: { status_id: status_b.id }
              },
              format: 'xml'
        end

        it { expect(response.response_code).to eq(expected_response_code) }

        it { expect(WorkPackage.find(planning_element.id).status).to eq(expected_work_package_status) }
      end

      context 'valid workflow exists' do
        let!(:workflow) {
          FactoryGirl.create(:workflow,
                             old_status: status_a,
                             new_status: status_b,
                             type_id: planning_element.type_id)
        }

        before { planning_element.project.add_member!(current_user, workflow.role) }

        it_behaves_like 'work package status change' do
          let(:expected_response_code) { 204 }
          let(:expected_work_package_status) { status_b }
        end
      end

      context 'no valid workflow exists' do
        it_behaves_like 'work package status change' do
          let(:expected_response_code) { 422 }
          let(:expected_work_package_status) { status_a }
        end
      end
    end
  end

  describe 'destroy.xml' do
    become_admin

    describe 'w/o a valid planning element id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', params: { id: '4711' }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', params: {  project_id: '4711', id: '1337' }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'destroy', params: {  project_id: project.id, id: '1337' }, format: 'xml'

            expect(response.response_code).to eq(403)
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_delete_planning_element_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            expect {
              get 'destroy', params: {  project_id: project.id, id: '1337' }, format: 'xml'
            }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid planning element id' do
      let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }
      let(:planning_element) { FactoryGirl.create(:work_package, project_id: project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'destroy', params: { id: planning_element.id }, format: 'xml'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            get 'destroy',
                params: { project_id: project.id, id: planning_element.id },
                format: :xml

            expect(response.response_code).to eq(403)
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_delete_planning_element_permissions

          it 'assigns the planning_element' do
            get 'destroy',
                params: { project_id: project.id, id: planning_element.id },
                format: :xml

            expect(assigns(:planning_element)).to eq(planning_element)
          end

          it 'renders the destroy builder template' do
            get 'destroy',
                params: { project_id: project.id, id: planning_element.id },
                format: :xml

            expect(response).to render_template('planning_elements/destroy')
          end

          it 'deletes the record' do
            get 'destroy',
                params: { project_id: project.id, id: planning_element.id },
                format: :xml
            expect {
              planning_element.reload
            }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end
end
