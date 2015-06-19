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

describe Api::V2::WorkflowsController, type: :controller do
  describe '#index' do
    describe 'unauthorized access' do
      let(:project) { FactoryGirl.create(:project) }

      before { get :index, project_id: project.id, format: :xml }

      it { expect(response.status).to eq(401) }
    end

    describe 'authorized access' do
      let(:current_user) { FactoryGirl.create(:user) }

      before { allow(User).to receive(:current).and_return current_user }

      shared_examples_for 'valid workflow index request' do
        it { expect(assigns(:project)).to eq(project) }

        it { expect(response).to render_template('api/v2/workflows/index', formats: ['api']) }
      end

      describe 'w/o project' do
        before { get :index, format: :xml }

        it { expect(response.status).to eq(404) }
      end

      describe 'with project' do
        let(:role_0) { FactoryGirl.create(:role) }
        let(:role_1) { FactoryGirl.create(:role) }
        let(:type_0) { FactoryGirl.create(:type) }
        let(:type_1) { FactoryGirl.create(:type) }
        let(:project) {
          FactoryGirl.create(:project,
                             types: [type_0, type_1])
        }
        let!(:member) {
          FactoryGirl.create(:member,
                             user: current_user,
                             project: project,
                             roles: [role_0, role_1])
        }

        before { get :index, project_id: project.id, format: :xml }

        it { expect(assigns(:workflows)).to be_empty }

        it_behaves_like 'valid workflow index request'

        describe 'workflows' do
          let(:status_0) { FactoryGirl.create(:status) }
          let(:status_1) { FactoryGirl.create(:status) }
          let(:status_2) { FactoryGirl.create(:status) }
          let(:status_3) { FactoryGirl.create(:status) }
          let(:status_4a) { FactoryGirl.create(:status) }
          let(:status_4b) { FactoryGirl.create(:status) }
          let!(:workflow_0a) {
            FactoryGirl.create(:workflow,
                               old_status: status_0,
                               new_status: status_1,
                               type_id: type_0.id,
                               role: role_0)
          }
          let!(:workflow_0b) {
            FactoryGirl.create(:workflow,
                               old_status: status_0,
                               new_status: status_1,
                               type_id: type_0.id,
                               role: role_1)
          }
          let!(:workflow_1a) {
            FactoryGirl.create(:workflow,
                               old_status: status_1,
                               new_status: status_2,
                               type_id: type_0.id,
                               role: role_0)
          }
          let!(:workflow_1b) {
            FactoryGirl.create(:workflow,
                               old_status: status_1,
                               new_status: status_3,
                               type_id: type_0.id,
                               role: role_0)
          }
          let!(:workflow_2) {
            FactoryGirl.create(:workflow,
                               old_status: status_2,
                               new_status: status_3,
                               type_id: type_1.id,
                               role: role_0)
          }
          let!(:workflow_3) {
            FactoryGirl.create(:workflow,
                               old_status: status_3,
                               new_status: status_4a,
                               type_id: type_1.id,
                               role: role_0,
                               author: true)
          }
          let!(:workflow_4a) {
            FactoryGirl.create(:workflow,
                               old_status: status_3,
                               new_status: status_4b,
                               type_id: type_1.id,
                               role: role_0,
                               assignee: true)
          }
          let!(:workflow_4b) {
            FactoryGirl.create(:workflow,
                               old_status: status_3,
                               new_status: status_4b,
                               type_id: type_1.id,
                               role: role_1,
                               assignee: false)
          }

          before { get :index, project_id: project.id, format: :xml }

          it_behaves_like 'valid workflow index request'

          describe '@workflow' do
            let(:workflows) { assigns(:workflows) }
            let(:type_ids) { [type_0.id, type_1.id] }
            let(:old_status_ids) { [status_0.id, status_1.id, status_2.id, status_3.id] }

            it { expect(workflows).not_to be_empty }

            it { expect(workflows.length).to eq(4) }

            it { expect(workflows.map(&:type_id).uniq).to match_array(type_ids) }

            it { expect(workflows.map(&:old_status_id).uniq).to match_array(old_status_ids) }

            describe 'transitions' do
              let(:transitions) { workflows.map(&:transitions).flatten }
              let(:workflows_by_type) { workflows.group_by(&:type_id) }
              let(:workflow_type_0_status_1) { workflows_by_type[type_0.id].detect { |w| w.old_status_id == status_1.id } }

              it { expect(transitions.length).to eq(6) }

              it { expect(workflows_by_type.length).to eq(2) }

              it { expect(workflow_type_0_status_1.transitions.length).to eq(2) }

              describe 'scope' do
                let(:workflow_type_0_roles) { workflows_by_type[type_0.id].map(&:transitions).flatten.map(&:scope) }
                let(:workflow_type_1_roles) { workflows_by_type[type_1.id].map(&:transitions).flatten.map(&:scope) }
                let(:workflow_type_1_status_3) { workflows_by_type[type_1.id].detect { |w| w.old_status_id == status_3.id } }

                it { expect(workflow_type_0_roles.length).to eq(3) }

                it { expect(workflow_type_0_roles.uniq).to match_array([:role]) }

                it { expect(workflow_type_1_roles.length).to eq(3) }

                it { expect(workflow_type_1_roles.uniq).to match_array([:role, :author, :assignee]) }

                it { expect(workflow_type_1_status_3.transitions.length).to eq(2) }

                it { expect(workflow_type_1_status_3.transitions.map(&:scope)).to match_array([:author, :assignee]) }
              end
            end
          end
        end
      end
    end
  end
end
