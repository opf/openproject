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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CostlogController, type: :controller do
  include Cost::PluginSpecHelper
  let (:project) { FactoryBot.create(:project_with_types) }
  let (:work_package) {
    FactoryBot.create(:work_package, project: project,
                                      author: user,
                                      type: project.types.first)
  }
  let (:user) { FactoryBot.create(:user) }
  let (:user2) { FactoryBot.create(:user) }
  let (:controller) { FactoryBot.build(:role, permissions: [:log_costs, :edit_cost_entries]) }
  let (:cost_type) { FactoryBot.build(:cost_type) }
  let (:cost_entry) {
    FactoryBot.build(:cost_entry, work_package: work_package,
                                   project: project,
                                   spent_on: Date.today,
                                   overridden_costs: 400,
                                   units: 100,
                                   user: user,
                                   comments: '')
  }
  let(:work_package_status) { FactoryBot.create(:work_package_status, is_default: true) }

  def grant_current_user_permissions(user, permissions)
    member = FactoryBot.build(:member, project: project,
                                        principal: user)
    member.roles << FactoryBot.build(:role, permissions: permissions)
    member.principal = user
    member.save!
    user.reload # in order to refresh the member/membership associations
    allow(User).to receive(:current).and_return(user)
  end

  def disable_flash_sweep
    allow(@controller.flash).to receive(:sweep)
  end

  shared_examples_for 'assigns' do
    it do
      expect(assigns(:cost_entry).project).to eq(expected_project)
      expect(assigns(:cost_entry).work_package).to eq(expected_work_package)
      expect(assigns(:cost_entry).user).to eq(expected_user)
      expect(assigns(:cost_entry).spent_on).to eq(expected_spent_on)
      expect(assigns(:cost_entry).cost_type).to eq(expected_cost_type)
      expect(assigns(:cost_entry).units).to eq(expected_units)
      expect(assigns(:cost_entry).overridden_costs).to eq(expected_overridden_costs)
    end
  end

  before do
    disable_flash_sweep
    allow(@controller).to receive(:check_if_login_required)
  end

  after do
    User.current = nil
  end

  describe 'GET new' do
    let(:params) { { 'work_package_id' => work_package.id.to_s } }

    let(:expected_project) { project }
    let(:expected_work_package) { work_package }
    let(:expected_user) { user }
    let(:expected_spent_on) { Date.today }
    let(:expected_cost_type) { nil }
    let(:expected_overridden_costs) { nil }
    let(:expected_units) { nil }

    shared_examples_for 'successful new' do
      before do
        get :new, params: params
      end

      it { expect(response).to be_successful }
      it_should_behave_like 'assigns'
      it { expect(response).to render_template('edit') }
    end

    shared_examples_for 'forbidden new' do
      before do
        get :new, params: params
      end

      it { expect(response.response_code).to eq(403) }
    end

    describe 'WHEN user allowed to create new cost_entry' do
      before do
        grant_current_user_permissions user, [:log_costs]
      end

      it_should_behave_like 'successful new'
    end

    describe "WHEN user allowed to create new cost_entry
              WHEN a default cost_type exists" do
      let(:expected_cost_type) { cost_type }

      before do
        cost_type.default = true
        cost_type.save!

        grant_current_user_permissions user, [:log_costs]
      end

      it_should_behave_like 'successful new'
    end

    describe 'WHEN user is allowed to create new own cost_entry' do
      before do
        grant_current_user_permissions user, [:log_own_costs]
      end

      it_should_behave_like 'successful new'
    end

    describe 'WHEN user is not allowed to create new cost_entries' do
      before do
        grant_current_user_permissions user, []
      end

      it_should_behave_like 'forbidden new'
    end
  end

  describe 'GET edit' do
    let(:params) { { 'id' => cost_entry.id.to_s } }

    before do
      cost_entry.save(validate: false)
    end

    shared_examples_for 'successful edit' do
      before do
        get :edit, params: params
      end

      it { expect(response).to be_successful }
      it { expect(assigns(:cost_entry)).to eq(cost_entry) }
      it { expect(assigns(:cost_entry)).not_to be_changed }
      it { expect(response).to render_template('edit') }
    end

    shared_examples_for 'forbidden edit' do
      before do
        get :edit, params: params
      end

      it { expect(response.response_code).to eq(403) }
    end

    describe 'WHEN the user is allowed to edit cost_entries' do
      before do
        grant_current_user_permissions user, [:edit_cost_entries]
      end

      it_should_behave_like 'successful edit'
    end

    describe "WHEN the user is allowed to edit cost_entries
              WHEN trying to edit a not own cost_entry" do
      before do
        grant_current_user_permissions user, [:edit_cost_entries]

        cost_entry.user = FactoryBot.create(:user)
        cost_entry.save(validate: false)
      end

      it_should_behave_like 'successful edit'
    end

    describe 'WHEN the user is allowed to edit own cost_entries' do
      before do
        grant_current_user_permissions user, [:edit_own_cost_entries]
      end

      it_should_behave_like 'successful edit'
    end

    describe "WHEN the user is allowed to edit own cost_entries
              WHEN trying to edit a not own cost_entry" do
      before do
        grant_current_user_permissions user, [:edit_own_cost_entries]

        cost_entry.user = FactoryBot.create(:user)
        cost_entry.save(validate: false)
      end

      it_should_behave_like 'forbidden edit'
    end

    describe 'WHEN the user is not allowed to edit cost_entries' do
      before do
        grant_current_user_permissions user, []
      end

      it_should_behave_like 'forbidden edit'
    end

    describe "WHEN the user is allowed to edit cost_entries
              WHEN the cost_entry is associated to a different project" do
      before do
        grant_current_user_permissions user, [:edit_cost_entries]

        cost_entry.project = FactoryBot.create(:project_with_types)
        cost_entry.work_package = FactoryBot.create(:work_package, project: cost_entry.project,
                                                                    type: cost_entry.project.types.first,
                                                                    author: user)
        cost_entry.save!
      end

      it_should_behave_like 'forbidden edit'
    end

    describe "WHEN the user is allowed to edit cost_entries
              WHEN the provided id is invalid" do
      before do
        grant_current_user_permissions user, [:edit_cost_entries]

        params['id'] = (cost_entry.id + 1).to_s

        get :edit, params: params
      end

      it { expect(response.response_code).to eq(404) }
    end
  end

  describe 'POST create' do
    let (:params) {
      { 'project_id' => project.id.to_s,
        'cost_entry' => { 'user_id' => user.id.to_s,
                          'work_package_id' => (work_package.present? ? work_package.id.to_s : ''),
                          'units' => units.to_s,
                          'cost_type_id' => (cost_type.present? ? cost_type.id.to_s : ''),
                          'comments' => 'lorem',
                          'spent_on' => date.to_s,
                          'overridden_costs' => overridden_costs.to_s } }
    }
    let(:expected_project) { project }
    let(:expected_work_package) { work_package }
    let(:expected_user) { user }
    let(:expected_overridden_costs) { overridden_costs }
    let(:expected_spent_on) { date }
    let(:expected_cost_type) { cost_type }
    let(:expected_units) { units }

    let(:user2) { FactoryBot.create(:user) }
    let(:date) { '2012-04-03'.to_date }
    let(:overridden_costs) { 500.00 }
    let(:units) { 5.0 }

    before do
      cost_type.save! if cost_type.present?
    end

    shared_examples_for 'successful create' do
      before do
        post :create, params: params
      end

      it { expect(response).to be_redirect }
      it { expect(assigns(:cost_entry)).not_to be_new_record }
      it_should_behave_like 'assigns'
      it { expect(flash[:notice]).to eql('Unit cost logged successfully.') }
    end

    shared_examples_for 'invalid create' do
      before do
        post :create, params: params
      end

      it { expect(response).to be_successful }
      it_should_behave_like 'assigns'
      it { expect(flash[:notice]).to be_nil }
    end

    shared_examples_for 'forbidden create' do
      before do
        post :create, params: params
      end

      it { expect(response.response_code).to eq(403) }
    end

    describe 'WHEN the user is allowed to create cost_entries' do
      before do
        grant_current_user_permissions user, [:log_costs]
      end

      it_should_behave_like 'successful create'
    end

    describe 'WHEN the user is allowed to create own cost_entries' do
      before do
        grant_current_user_permissions user, [:log_own_costs]
      end

      it_should_behave_like 'successful create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN no date is specified" do
      let(:expected_spent_on) { Date.today }

      before do
        grant_current_user_permissions user, [:log_costs]

        params['cost_entry'].delete('spent_on')
      end

      it_should_behave_like 'successful create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN a non existing cost_type_id is specified
              WHEN no default cost_type is defined" do
      let(:expected_cost_type) { nil }

      before do
        grant_current_user_permissions user, [:log_costs]
        params['cost_entry']['cost_type_id'] = (cost_type.id + 1).to_s
      end

      it_should_behave_like 'invalid create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN a non existing cost_type_id is specified
              WHEN a default cost_type is defined" do
      let(:expected_cost_type) { nil }

      before do
        FactoryBot.create(:cost_type, default: true)

        grant_current_user_permissions user, [:log_costs]
        params['cost_entry']['cost_type_id'] = 1
      end

      it_should_behave_like 'invalid create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN no cost_type is specified
              WHEN a default cost_type is defined" do
      let(:expected_cost_type) { nil }

      before do
        FactoryBot.create(:cost_type, default: true)

        grant_current_user_permissions user, [:log_costs]
        params['cost_entry'].delete('cost_type_id')
      end

      it_should_behave_like 'invalid create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN no cost_type is specified
              WHEN no default cost_type is defined" do
      let(:expected_cost_type) { nil }

      before do
        grant_current_user_permissions user, [:log_costs]
        params['cost_entry'].delete('cost_type_id')
      end

      it_should_behave_like 'invalid create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN the cost_type id provided belongs to an inactive cost_type" do
      before do
        grant_current_user_permissions user, [:log_costs]
        cost_type.deleted_at = Date.today
        cost_type.save!
      end

      it_should_behave_like 'invalid create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN the user is allowed to log cost for someone else and is doing so
              WHEN the other user is a member of the project" do
      before do
        grant_current_user_permissions user, []
        grant_current_user_permissions user2, [:log_costs]

        params['cost_entry']['user_id'] = user.id.to_s
      end

      it_should_behave_like 'successful create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN the user is allowed to log cost for someone else and is doing so
              WHEN the other user isn't a member of the project" do
      before do
        grant_current_user_permissions user2, [:log_costs]

        params['cost_entry']['user_id'] = user.id.to_s
      end

      it_should_behave_like 'invalid create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN the id of an work_package not included in the provided project is provided" do
      let(:project2) { FactoryBot.create(:project_with_types) }
      let(:work_package2) {
        FactoryBot.create(:work_package, project: project2,
                                          type: project2.types.first,
                                          author: user)
      }
      let(:expected_work_package) { work_package2 }

      before do
        grant_current_user_permissions user, [:log_costs]

        params['cost_entry']['work_package_id'] = work_package2.id
      end

      it_should_behave_like 'invalid create'
    end

    describe "WHEN the user is allowed to create cost_entries
              WHEN no work_package_id is provided" do
      let(:expected_work_package) { nil }

      before do
        grant_current_user_permissions user, [:log_costs]

        params['cost_entry'].delete('work_package_id')
      end

      it_should_behave_like 'invalid create'
    end

    describe "WHEN the user is allowed to create own cost_entries
              WHEN the user is trying to log costs for somebody else" do
      before do
        grant_current_user_permissions user2, [:log_own_costs]

        params['cost_entry']['user_id'] = user.id
      end

      it_should_behave_like 'forbidden create'
    end

    describe 'WHEN the user is not allowed to create cost_entries' do
      before do
        grant_current_user_permissions user, []
      end

      it_should_behave_like 'forbidden create'
    end
  end

  describe 'PUT update' do
    let(:params) {
      { 'id' => cost_entry.id.to_s,
        'cost_entry' => { 'comments' => 'lorem',
                          'work_package_id' => cost_entry.work_package.id.to_s,
                          'units' => cost_entry.units.to_s,
                          'spent_on' => cost_entry.spent_on.to_s,
                          'user_id' => cost_entry.user.id.to_s,
                          'cost_type_id' => cost_entry.cost_type.id.to_s } }
    }

    before do
      cost_entry.save(validate: false)
    end

    let(:expected_work_package) { cost_entry.work_package }
    let(:expected_user) { cost_entry.user }
    let(:expected_project) { cost_entry.project }
    let(:expected_cost_type) { cost_entry.cost_type }
    let(:expected_units) { cost_entry.units }
    let(:expected_overridden_costs) { cost_entry.overridden_costs }
    let(:expected_spent_on) { cost_entry.spent_on }

    shared_examples_for 'successful update' do
      before do
        put :update, params: params
      end

      it { expect(response).to be_redirect }
      it { expect(assigns(:cost_entry)).to eq(cost_entry) }
      it_should_behave_like 'assigns'
      it { expect(assigns(:cost_entry)).not_to be_changed }
      it { expect(flash[:notice]).to eql I18n.t(:notice_successful_update) }
    end

    shared_examples_for 'invalid update' do
      before do
        put :update, params: params
      end

      it_should_behave_like 'assigns'
      it { expect(response).to be_successful }
      it { expect(flash[:notice]).to be_nil }
    end

    shared_examples_for 'forbidden update' do
      before do
        put :update, params: params
      end

      it { expect(response.response_code).to eq(403) }
    end

    describe "WHEN the user is allowed to update cost_entries
              WHEN updating:
                work_package_id
                user_id
                units
                cost_type
                overridden_costs
                spent_on" do
      let(:expected_work_package) {
        FactoryBot.create(:work_package, project: project,
                                          type: project.types.first,
                                          author: user)
      }
      let(:expected_user) { FactoryBot.create(:user) }
      let(:expected_spent_on) { cost_entry.spent_on + 4.days }
      let(:expected_units) { cost_entry.units + 20 }
      let(:expected_cost_type) { FactoryBot.create(:cost_type) }
      let(:expected_overridden_costs) { cost_entry.overridden_costs + 300 }

      before do
        grant_current_user_permissions expected_user, []
        grant_current_user_permissions user, [:edit_cost_entries]

        params['cost_entry']['work_package_id'] = expected_work_package.id.to_s
        params['cost_entry']['user_id'] = expected_user.id.to_s
        params['cost_entry']['spent_on'] = expected_spent_on.to_s
        params['cost_entry']['units'] = expected_units.to_s
        params['cost_entry']['cost_type_id'] = expected_cost_type.id.to_s
        params['cost_entry']['overridden_costs'] = expected_overridden_costs.to_s
      end

      it_should_behave_like 'successful update'
    end

    describe "WHEN the user is allowed to update cost_entries
              WHEN updating nothing" do
      before do
        grant_current_user_permissions user, [:edit_cost_entries]
      end

      it_should_behave_like 'successful update'
    end

    describe "WHEN the user is allowed ot update own cost_entries
              WHEN updating something" do
      let(:expected_units) { cost_entry.units + 20 }

      before do
        grant_current_user_permissions user, [:edit_own_cost_entries]

        params['cost_entry']['units'] = expected_units.to_s
      end

      it_should_behave_like 'successful update'
    end

    describe "WHEN the user is allowed to update cost_entries
              WHEN updating the user
              WHEN the new user isn't a member of the project" do
      let(:user2) { FactoryBot.create(:user) }
      let(:expected_user) { user2 }

      before do
        grant_current_user_permissions user, [:edit_cost_entries]

        params['cost_entry']['user_id'] = user2.id.to_s
      end

      it_should_behave_like 'invalid update'
    end

    describe "WHEN the user is allowed to update cost_entries
              WHEN updating the work_package
              WHEN the new work_package isn't an work_package of the current project" do
      let(:project2) { FactoryBot.create(:project_with_types) }
      let(:work_package2) {
        FactoryBot.create(:work_package, project: project2,
                                          type: project2.types.first)
      }
      let(:expected_work_package) { work_package2 }

      before do
        grant_current_user_permissions user, [:edit_cost_entries]

        params['cost_entry']['work_package_id'] = work_package2.id.to_s
      end

      it_should_behave_like 'invalid update'
    end

    describe "WHEN the user is allowed to update cost_entries
              WHEN updating the work_package
              WHEN the new work_package_id isn't existing" do
      let(:expected_work_package) { nil }

      before do
        grant_current_user_permissions user, [:edit_cost_entries]

        params['cost_entry']['work_package_id'] = (work_package.id + 1).to_s
      end

      it_should_behave_like 'invalid update'
    end

    describe "WHEN the user is allowed to update cost_entries
              WHEN updating the cost_type
              WHEN the new cost_type is deleted" do
      let(:expected_cost_type) { FactoryBot.create(:cost_type, deleted_at: Date.today) }

      before do
        grant_current_user_permissions user, [:edit_cost_entries]

        params['cost_entry']['cost_type_id'] = expected_cost_type.id.to_s
      end

      it_should_behave_like 'invalid update'
    end

    describe "WHEN the user is allowed to update cost_entries
              WHEN updating the cost_type
              WHEN the new cost_type doesn't exist" do
      let(:expected_cost_type) { nil }

      before do
        grant_current_user_permissions user, [:edit_cost_entries]

        params['cost_entry']['cost_type_id'] = '1'
      end

      it_should_behave_like 'invalid update'
    end

    describe "WHEN the user is allowed to update own cost_entries and not all
              WHEN updating own cost entry
              WHEN updating the user" do
      let(:user3) { FactoryBot.create(:user) }

      before do
        grant_current_user_permissions user, [:edit_own_cost_entries]

        params['cost_entry']['user_id'] = user3.id
      end

      it_should_behave_like 'forbidden update'
    end

    describe "WHEN the user is allowed to update own cost_entries and not all
              WHEN updating foreign cost_entry
              WHEN updating someting" do
      let(:user3) { FactoryBot.create(:user) }

      before do
        grant_current_user_permissions user3, [:edit_own_cost_entries]

        params['cost_entry']['units'] = (cost_entry.units + 20).to_s
      end

      it_should_behave_like 'forbidden update'
    end
  end
end
