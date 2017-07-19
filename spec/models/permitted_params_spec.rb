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

describe PermittedParams, type: :model do
  let(:user) { FactoryGirl.build(:user) }
  let(:admin) { FactoryGirl.build(:admin) }

  shared_context 'prepare params comparison' do
    let(:params_key) { defined?(hash_key) ? hash_key : attribute }
    let(:params) do
      nested_params = if defined?(nested_key)
                        { nested_key => hash }
                      else
                        hash
                      end

      ac_params = if defined?(flat) && flat
                    nested_params
                  else
                    { params_key => nested_params }
                  end

      ActionController::Parameters.new(ac_params)
    end

    subject { PermittedParams.new(params, user).send(attribute).to_h }
  end

  shared_examples_for 'allows params' do
    include_context 'prepare params comparison'

    it do
      expected = defined?(allowed_params) ? allowed_params : hash
      expect(subject).to eq(expected)
    end
  end

  shared_examples_for 'allows nested params' do
    include_context 'prepare params comparison'

    it { expect(subject).to eq(hash) }
  end

  shared_examples_for 'forbids params' do
    include_context 'prepare params comparison'

    it { expect(subject).not_to eq(hash) }
  end

  describe '#permit' do
    it 'adds an attribute to be permitted later' do
      # just taking project_type here as an example, could be anything

      # taking the originally whitelisted params to be restored later
      original_whitelisted = PermittedParams.instance_variable_get(:@whitelisted_params)

      params = ActionController::Parameters.new(project_type: { 'blubs1' => 'blubs' })

      expect(PermittedParams.new(params, user).project_type.to_h).to eq({})

      PermittedParams.permit(:project_type, :blubs1)

      expect(PermittedParams.new(params, user).project_type.to_h).to eq('blubs1' => 'blubs')

      PermittedParams.instance_variable_set(:@whitelisted_params, original_whitelisted)
    end

    it 'raises an argument error if key does not exist' do
      expect { PermittedParams.permit(:bogus_key) }.to raise_error ArgumentError
    end
  end

  describe '#project_type' do
    let(:attribute) { :project_type }

    describe 'name' do
      let(:hash) { { 'name' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    describe 'allows_association' do
      let(:hash) { { 'allows_association' => '1' } }

      it_behaves_like 'allows params'
    end

    describe 'allows_association' do
      let(:hash) { { 'reported_project_status_ids' => ['1'] } }

      it_behaves_like 'allows params'
    end
  end

  describe '#project_type_move' do
    let(:attribute) { :project_type_move }
    let(:hash_key) { :project_type }

    describe 'move_to' do
      let(:hash) { { 'move_to' => '1' } }

      it_behaves_like 'allows params'
    end
  end

  describe '#timeline' do
    let(:attribute) { :timeline }

    context 'all acceptable options params and one name params' do
      let(:hash) do
        acceptable_options_params = ['exist', 'zoom_factor', 'initial_outline_expansion', 'timeframe_start',
                                     'timeframe_end', 'columns', 'project_sort', 'compare_to_relative',
                                     'compare_to_relative_unit', 'compare_to_absolute', 'vertical_planning_elements',
                                     'exclude_own_planning_elements', 'planning_element_status',
                                     'planning_element_types', 'planning_element_responsibles',
                                     'planning_element_assignee', 'exclude_reporters', 'exclude_empty', 'project_types',
                                     'project_status', 'project_responsibles', 'parents', 'planning_element_time_types',
                                     'planning_element_time_absolute_one', 'planning_element_time_absolute_two',
                                     'planning_element_time_relative_one', 'planning_element_time_relative_one_unit',
                                     'planning_element_time_relative_two', 'planning_element_time_relative_two_unit',
                                     'grouping_one_enabled', 'grouping_one_selection', 'grouping_one_sort', 'hide_other_group']

        acceptable_options_params_with_data = HashWithIndifferentAccess[acceptable_options_params.map { |x| [x, 'value'] }]

        { 'name' => 'my name', 'options' => acceptable_options_params_with_data }
      end

      it_behaves_like 'allows params'
    end

    context 'only name' do
      let(:hash) { { 'name' => 'my name' } }

      it_behaves_like 'allows params'
    end
  end

  describe '#pref' do
    let(:attribute) { :pref }

    let(:hash) do
      acceptable_params = %w(hide_mail time_zone impaired
                             comments_sorting warn_on_leaving_unsaved)

      acceptable_params.map { |x| [x, 'value'] }.to_h
    end

    it_behaves_like 'allows params'
  end

  describe '#time_entry' do
    let(:attribute) { :time_entry }

    context 'whitelisted params' do
      let(:hash) do
        acceptable_params = %w(hours comments work_package_id
                               activity_id spent_on)

        acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map { |x| [x, 'value'] }]

        acceptable_params_with_data['custom_field_values'] = { '1' => 'foo', '2' => 'bar', '3' => 'baz' }

        acceptable_params_with_data
      end

      it_behaves_like 'allows params'
    end

    context 'empty' do
      let(:hash) { {} }

      it_behaves_like 'allows params'
    end
  end

  describe '#news' do
    let(:attribute) { :news }
    let(:hash) do
      %w(title summary description).map { |x| [x, 'value'] }.to_h
    end

    it_behaves_like 'allows params'
  end

  describe '#comment' do
    let(:attribute) { :comment }
    let(:hash) do
      %w(commented author comments).map { |x| [x, 'value'] }.to_h
    end

    it_behaves_like 'allows params'
  end

  describe '#watcher' do
    let(:attribute) { :watcher }
    let(:hash) do
      %w(watchable user user_id).map { |x| [x, 'value'] }.to_h
    end

    it_behaves_like 'allows params'
  end

  describe '#reply' do
    let(:attribute) { :reply }
    let(:hash) do
      %w(content subject).map { |x| [x, 'value'] }.to_h
    end

    it_behaves_like 'allows params'
  end

  describe '#wiki' do
    let(:attribute) { :wiki }
    let(:hash) do
      %w(start_page).map { |x| [x, 'value'] }.to_h
    end

    it_behaves_like 'allows params'
  end

  describe '#reporting' do
    let(:attribute) { :reporting }

    context 'whitelisted params' do
      let(:hash) do
        %w(reporting_to_project_id
           reported_project_status_id
           reported_project_status_comment).map { |x| [x, 'value'] }.to_h
      end

      it_behaves_like 'allows params'
    end

    context 'empty' do
      let(:hash) { {} }

      it_behaves_like 'allows params'
    end
  end

  describe '#membership' do
    let(:attribute) { :membership }
    let(:hash) do
      { 'project_id' => '1', 'role_ids' => ['1', '2', '4'] }
    end

    it_behaves_like 'allows params'
  end

  describe '#category' do
    let(:attribute) { :category }
    let(:hash) do
      %w(name assigned_to_id).map { |x| [x, 'value'] }.to_h
    end

    it_behaves_like 'allows params'
  end

  describe '#version' do
    let(:attribute) { :version }

    context 'whitelisted params' do
      let(:hash) do
        %w(name description effective_date due_date
           start_date wiki_page_title status sharing).map { |x| [x, 'value'] }.to_h
      end

      it_behaves_like 'allows params'
    end

    context 'empty' do
      let(:hash) { {} }

      it_behaves_like 'allows params'
    end

    context 'custom field values' do
      let(:hash) { { 'custom_field_values' => { '1' => '5' } } }

      it_behaves_like 'allows params'
    end
  end

  describe '#message' do
    let(:attribute) { :message }

    context 'no instance passed' do
      let(:allowed_params) do
        %w(subject content board_id).map { |x| [x, 'value'] }.to_h
      end

      let(:hash) do
        allowed_params.merge('evil': 'true', 'sticky': 'true', 'locked': 'true')
      end

      it_behaves_like 'allows params'
    end

    context 'empty' do
      let(:hash) { {} }

      it_behaves_like 'allows params'
    end

    context 'with instance passed' do
      let(:instance) { double('message', project: double('project')) }
      let(:allowed_params) do
        { 'subject' => 'value',
          'content' => 'value',
          'board_id' => 'value',
          'sticky' => 'true',
          'locked' => 'true' }
      end

      let(:hash) do
        ActionController::Parameters.new('message' => allowed_params.merge('evil': 'true'))
      end

      before do
        allow(user).to receive(:allowed_to?).with(:edit_messages, instance.project).and_return(true)
      end

      subject { PermittedParams.new(hash, user).message(instance).to_h }

      it do
        expect(subject).to eq(allowed_params)
      end
    end
  end

  describe '#attachments' do
    let(:attribute) { :attachments }

    let(:hash) do
      { 'file' => 'myfile',
        'description' => 'mydescription' }
    end

    it_behaves_like 'allows params'
  end

  describe '#projects_type_ids' do
    let(:attribute) { :projects_type_ids }
    let(:hash_key) { 'project' }

    let(:hash) do
      { 'type_ids' => ['1', '', '2'] }
    end

    let(:allowed_params) do
      [1, 2]
    end

    include_context 'prepare params comparison'

    it do
      actual = PermittedParams.new(params, user).send(attribute)

      expect(actual).to eq(allowed_params)
    end
  end

  describe '#color' do
    let(:attribute) { :color }

    let(:hash) do
      { 'name' => 'blubs',
        'hexcode' => '#fff' }
    end

    it_behaves_like 'allows params'
  end

  describe '#color_move' do
    let(:attribute) { :color_move }
    let(:hash_key) { 'color' }

    let(:hash) do
      { 'move_to' => '1' }
    end

    it_behaves_like 'allows params'
  end

  describe '#custom_field' do
    let(:attribute) { :custom_field }

    let(:hash) do
      { 'editable' => '0', 'visible' => '0' }
    end

    it_behaves_like 'allows params'
  end

  describe '#planning_element_type' do
    let(:attribute) { :planning_element_type }

    context 'name' do
      let(:hash) { { 'name' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    context 'in_aggregation' do
      let(:hash) { { 'in_aggregation' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'is_milestone' do
      let(:hash) { { 'is_milestone' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'is_default' do
      let(:hash) { { 'is_default' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'color_id' do
      let(:hash) { { 'color_id' => '1' } }

      it_behaves_like 'allows params'
    end
  end

  describe '#planning_element_type_move' do
    let(:attribute) { :planning_element_type_move }
    let(:hash_key) { 'planning_element_type' }

    context 'move_to' do
      let(:hash) { { 'move_to' => '1' } }

      it_behaves_like 'allows params'
    end
  end

  describe "#update_work_package" do
    let(:attribute) { :update_work_package }
    let(:hash_key) { 'work_package' }

    context 'subject' do
      let(:hash) { { 'subject' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    context 'description' do
      let(:hash) { { 'description' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    context 'start_date' do
      let(:hash) { { 'start_date' => '2013-07-08' } }

      it_behaves_like 'allows params'
    end

    context 'due_date' do
      let(:hash) { { 'due_date' => '2013-07-08' } }

      it_behaves_like 'allows params'
    end

    context 'assigned_to_id' do
      let(:hash) { { 'assigned_to_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'responsible_id' do
      let(:hash) { { 'responsible_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'type_id' do
      let(:hash) { { 'type_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'priority_id' do
      let(:hash) { { 'priority_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'parent_id' do
      let(:hash) { { 'parent_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'parent_id' do
      let(:hash) { { 'parent_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'fixed_version_id' do
      let(:hash) { { 'fixed_version_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'estimated_hours' do
      let(:hash) { { 'estimated_hours' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'done_ratio' do
      let(:hash) { { 'done_ratio' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'lock_version' do
      let(:hash) { { 'lock_version' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'status_id' do
      let(:hash) { { 'status_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'category_id' do
      let(:hash) { { 'category_id' => '1' } }

      it_behaves_like 'allows params'
    end

    context 'notes' do
      let(:hash) { { 'journal_notes' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    context 'attachments' do
      let(:hash) { { 'attachments' => [{ 'file' => 'djskfj', 'description' => 'desc' }] } }

      it_behaves_like 'allows params'
    end

    context 'watcher_user_ids' do
      include_context 'prepare params comparison'
      let(:hash) { { 'watcher_user_ids' => ['1', '2'] } }
      let(:project) { double('project') }

      before do
        allow(user).to receive(:allowed_to?).with(:add_work_package_watchers, project).and_return(allowed_to)
      end

      subject { PermittedParams.new(params, user).update_work_package(project: project).to_h }

      context 'user is allowed to add watchers' do
        let(:allowed_to) { true }

        it do
          expect(subject).to eq(hash)
        end
      end

      context 'user is not allowed to add watchers' do
        let(:allowed_to) { false }

        it do
          expect(subject).to eq({})
        end
      end
    end

    context 'time_entry' do
      include_context 'prepare params comparison'

      let(:hash) { { 'time_entry' => { 'hours' => '5', 'activity_id' => '1', 'comments' => 'lorem' } } }
      let(:project) { double('project') }

      before do
        allow(user).to receive(:allowed_to?).with(:log_time, project).and_return(allowed_to)
      end

      subject { PermittedParams.new(params, user).update_work_package(project: project).to_h }

      context 'user has the log_time permission' do
        let(:allowed_to) { true }

        it do
          expect(subject).to eq(hash)
        end
      end

      context 'user lacks the log_time permission' do
        let(:allowed_to) { false }

        it do
          expect(subject).to eq({})
        end
      end
    end

    context 'custom field values' do
      let(:hash) { { 'custom_field_values' => { '1' => '5' } } }

      it_behaves_like 'allows params'
    end

    context "removes custom field values that do not follow the schema 'id as string' => 'value as string'" do
      let(:hash) { { 'custom_field_values' => { 'blubs' => '5', '5' => { '1' => '2' } } } }

      it_behaves_like 'forbids params'
    end
  end

  describe '#user' do
    include_context 'prepare params comparison'

    let(:hash_key) { 'user' }
    let(:external_authentication) { false }
    let(:change_password_allowed) { true }

    subject { PermittedParams.new(params, user).send(attribute, external_authentication, change_password_allowed).to_h }

    admin_permissions = ['admin',
                         'login',
                         'firstname',
                         'lastname',
                         'mail',
                         'mail_notification',
                         'language',
                         'custom_fields',
                         'auth_source_id',
                         'force_password_change']

    %i(user_update_as_admin user_create_as_admin).each do |method|
      describe method do
        let(:attribute) { method }

        context 'non-admin' do
          let(:hash) { Hash[admin_permissions.zip(admin_permissions)] }

          it 'permits nothing' do
            expect(subject).to eq({})
          end
        end

        context 'admin' do
          let(:user) { admin }

          admin_permissions.each do |field|
            context field do
              let(:hash) { { field => 'test' } }

              it "permits #{field}" do
                expect(subject).to eq(field => 'test')
              end
            end
          end

          context 'with no password change allowed' do
            let(:hash) { { 'force_password_change' => 'true' } }
            let(:change_password_allowed) { false }

            it 'does not permit force_password_change' do
              expect(subject).to eq({})
            end
          end

          context 'with external authentication' do
            let(:hash) { { 'auth_source_id' => 'true' } }
            let(:external_authentication) { true }

            it 'does not permit auth_source_id' do
              expect(subject).to eq({})
            end
          end

          context 'custom field values' do
            let(:hash) { { 'custom_field_values' => { '1' => '5' } } }

            it 'permits custom_field_values' do
              expect(subject).to eq(hash)
            end
          end

          context "custom field values that do not follow the schema 'id as string' => 'value as string'" do
            let(:hash) { { 'custom_field_values' => { 'blubs' => '5', '5' => { '1' => '2' } } } }

            it 'are removed' do
              expect(subject).to eq({})
            end
          end
        end
      end
    end

    describe '#user_update_as_admin' do
      let(:attribute) { :user_update_as_admin }
      let(:user) { admin }

      context 'group_ids' do
        let(:hash) { { 'group_ids' => ['1', '2'] } }

        it 'permits group_ids' do
          expect(subject).to eq(hash)
        end
      end
    end

    describe '#user_create_as_admin' do
      let(:attribute) { :user_create_as_admin }
      let(:user) { admin }

      context 'group_ids' do
        let(:hash) { { 'group_ids' => ['1', '2'] } }

        it 'forbids group_ids' do
          expect(subject).to eq({})
        end
      end
    end

    user_permissions = [
      'firstname',
      'lastname',
      'mail',
      'mail_notification',
      'language',
      'custom_fields'
    ]

    describe '#user' do
      let(:attribute) { :user }
      let(:user) { admin }

      user_permissions.each do |field|
        context field do
          let(:hash) { { field => 'test' } }

          it_behaves_like 'allows params'
        end
      end

      (admin_permissions - user_permissions).each do |field|
        context "#{field} (admin-only)" do
          let(:hash) { { field => 'test' } }

          it_behaves_like 'forbids params'
        end
      end

      context 'custom field values' do
        let(:hash) { { 'custom_field_values' => { '1' => '5' } } }

        it_behaves_like 'allows params'
      end

      context "custom field values that do not follow the schema 'id as string' => 'value as string'" do
        let(:hash) { { 'custom_field_values' => { 'blubs' => '5', '5' => { '1' => '2' } } } }

        it_behaves_like 'forbids params'
      end

      context 'identity_url' do
        let(:hash) { { 'identity_url' => 'test_identity_url' } }

        it_behaves_like 'forbids params'
      end
    end
  end

  describe '#user_register_via_omniauth' do
    let(:attribute) { :user_register_via_omniauth }
    let(:hash_key) { 'user' }

    user_permissions = %w(login firstname lastname mail language)

    user_permissions.each do |field|
      let(:hash) { { field => 'test' } }

      it_behaves_like 'allows params'
    end

    context 'identity_url' do
      let(:hash) { { 'identity_url' => 'test_identity_url' } }

      it_behaves_like 'forbids params'
    end
  end

  shared_examples_for 'allows enumeration move params' do
    let(:hash) { { '2' => { 'move_to' => 'lower' } } }

    it_behaves_like 'allows params'
  end

  shared_examples_for 'allows move params' do
    let(:hash) { { 'move_to' => 'lower' } }

    it_behaves_like 'allows params'
  end

  shared_examples_for 'allows custom fields' do
    describe 'valid custom fields' do
      let(:hash) { { '1' => { 'custom_field_values' => { '1' => '5' } } } }

      it_behaves_like 'allows params'
    end

    describe 'invalid custom fields' do
      let(:hash) { { 'custom_field_values' => { 'blubs' => '5', '5' => { '1' => '2' } } } }

      it_behaves_like 'forbids params'
    end
  end

  describe '#status' do
    let (:attribute) { :status }

    describe 'name' do
      let(:hash) { { 'name' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    describe 'default_done_ratio' do
      let(:hash) { { 'default_done_ratio' => '10' } }

      it_behaves_like 'allows params'
    end

    describe 'is_closed' do
      let(:hash) { { 'is_closed' => 'true' } }

      it_behaves_like 'allows params'
    end

    describe 'is_default' do
      let(:hash) { { 'is_default' => 'true' } }

      it_behaves_like 'allows params'
    end

    describe 'move_to' do
      it_behaves_like 'allows move params'
    end
  end

  describe '#settings' do
    let (:attribute) { :settings }

    describe 'with password login enabled' do
      before do
        allow(OpenProject::Configuration)
          .to receive(:disable_password_login?)
          .and_return(false)
      end

      let(:hash) do
        {
          'sendmail_arguments' => 'value',
          'brute_force_block_after_failed_logins' => 'value',
          'password_active_rules' => ['value'],
          'default_projects_modules' => ['value', 'value'],
          'emails_footer' => { 'en' => 'value' }
        }
      end

      it_behaves_like 'allows params'
    end

    describe 'with password login disabld' do
      include_context 'prepare params comparison'

      before do
        allow(OpenProject::Configuration)
          .to receive(:disable_password_login?)
          .and_return(true)
      end

      let(:hash) do
        {
          'sendmail_arguments' => 'value',
          'brute_force_block_after_failed_logins' => 'value',
          'password_active_rules' => ['value'],
          'default_projects_modules' => ['value', 'value'],
          'emails_footer' => { 'en' => 'value' }
        }
      end

      let(:permitted_hash) do
        {
          'sendmail_arguments' => 'value',
          'brute_force_block_after_failed_logins' => 'value',
          'default_projects_modules' => ['value', 'value'],
          'emails_footer' => { 'en' => 'value' }
        }
      end

      it { expect(subject).to eq(permitted_hash) }
    end
  end

  describe '#enumerations' do
    let (:attribute) { :enumerations }

    describe 'name' do
      let(:hash) { { '1' => { 'name' => 'blubs' } } }

      it_behaves_like 'allows params'
    end

    describe 'active' do
      let(:hash) { { '1' => { 'active' => 'true' } } }

      it_behaves_like 'allows params'
    end

    describe 'is_default' do
      let(:hash) { { '1' => { 'is_default' => 'true' } } }

      it_behaves_like 'allows params'
    end

    describe 'reassign_to_id' do
      let(:hash) { { '1' => { 'reassign_to_id' => '1' } } }

      it_behaves_like 'allows params'
    end

    describe 'move_to' do
      it_behaves_like 'allows enumeration move params'
    end

    describe 'custom fields' do
      it_behaves_like 'allows custom fields'
    end
  end

  describe '#wiki_page_rename' do
    let(:hash_key) { :page }
    let (:attribute) { :wiki_page_rename }

    describe 'title' do
      let(:hash) { { 'title' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    describe 'redirect_existing_links' do
      let(:hash) { { 'redirect_existing_links' => '1' } }

      it_behaves_like 'allows params'
    end
  end

  describe '#wiki_page' do
    let(:hash_key) { :content }
    let(:nested_key) { :page }
    let (:attribute) { :wiki_page }

    describe 'title' do
      let(:hash) { { 'title' => 'blubs' } }

      it_behaves_like 'allows nested params'
    end

    describe 'parent_id' do
      let(:hash) { { 'parent_id' => '1' } }

      it_behaves_like 'allows nested params'
    end

    describe 'redirect_existing_links' do
      let(:hash) { { 'redirect_existing_links' => '1' } }

      it_behaves_like 'allows nested params'
    end
  end

  describe '#wiki_content' do
    let (:hash_key) { :content }
    let (:attribute) { :wiki_content }

    describe 'title' do
      let(:hash) { { 'comments' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    describe 'text' do
      let(:hash) { { 'text' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    describe 'lock_version' do
      let(:hash) { { 'lock_version' => '1' } }

      it_behaves_like 'allows params'
    end
  end

  describe 'member' do
    let (:attribute) { :member }

    describe 'role_ids' do
      let(:hash) { { 'role_ids' => [] } }

      it_behaves_like 'allows params'
    end

    describe 'user_id' do
      let(:hash) { { 'user_id' => 'blubs' } }

      it_behaves_like 'forbids params'
    end

    describe 'project_id' do
      let(:hash) { { 'user_id' => 'blubs' } }

      it_behaves_like 'forbids params'
    end

    describe 'created_on' do
      let(:hash) { { 'created_on' => 'blubs' } }

      it_behaves_like 'forbids params'
    end

    describe 'mail_notification' do
      let(:hash) { { 'mail_notification' => 'blubs' } }

      it_behaves_like 'forbids params'
    end
  end

  describe 'calendar_filter' do
    let(:attribute) { :calendar_filter }
    let(:flat) { true }

    describe 'project_id' do
      let(:hash) { { 'project_id' => 'some_identifier' } }

      it_behaves_like 'allows params'
    end

    describe 'f' do
      let(:hash) { { 'f' => ['assigned_to_id', 'subject'] } }

      it_behaves_like 'allows params'
    end

    describe 'op' do
      let(:hash) { { 'op' => { 'assigned_to_id' => '=', 'subject' => '~', 'cf_0815' => '=' } } }

      it_behaves_like 'allows params'
    end

    describe 'v' do
      let(:hash) { { 'v' => { 'assigned_to_id' => ['1'], 'subject' => ['blubs'], 'cf_0815' => ['a', 'b', 'c'] } } }

      it_behaves_like 'allows params'
    end

    describe 'month' do
      let(:hash) { { 'month' => '3' } }

      it_behaves_like 'allows params'
    end

    describe 'year' do
      let(:hash) { { 'year' => '3' } }

      it_behaves_like 'allows params'
    end
  end

  describe '.add_permitted_attributes' do
    before do
      @original_permitted_attributes = PermittedParams.permitted_attributes.clone
    end

    after do
      # Class variable is not accessible within class_eval
      original_permitted_attributes = @original_permitted_attributes

      PermittedParams.class_eval do
        @whitelisted_params = original_permitted_attributes
      end
    end

    describe 'with a known key' do
      let(:attribute) { :user }

      before do
        PermittedParams.send(:add_permitted_attributes, user: [:a_test_field])
      end

      context 'with an allowed parameter' do
        let(:hash) { { 'a_test_field' => 'a test value' } }

        it_behaves_like 'allows params'
      end

      context 'with a disallowed parameter' do
        let(:hash) { { 'a_not_allowed_field' => 'a test value' } }

        it_behaves_like 'forbids params'
      end
    end

    describe 'with an unknown key' do
      let(:attribute) { :unknown_key }
      let(:hash) { { 'a_test_field' => 'a test value' } }

      before do
        expect(Rails.logger).not_to receive(:warn)
        PermittedParams.send(:add_permitted_attributes, unknown_key: [:a_test_field])
      end

      it 'permitted attributes should include the key' do
        expect(PermittedParams.permitted_attributes.keys).to include(:unknown_key)
      end
    end
  end
end
