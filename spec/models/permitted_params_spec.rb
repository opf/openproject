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

require File.expand_path('../../spec_helper', __FILE__)

describe PermittedParams, type: :model do
  let(:user) { FactoryGirl.build(:user) }
  let(:admin) { FactoryGirl.build(:admin) }

  describe '#permit' do
    it 'adds an attribute to be permitted later' do
      # just taking project_type here as an example, could be anything

      # taking the originally whitelisted params to be restored later
      original_whitelisted = PermittedParams.instance_variable_get(:@whitelisted_params)

      params = ActionController::Parameters.new(project_type: { 'blubs1' => 'blubs' })

      expect(PermittedParams.new(params, user).project_type).to eq({})

      PermittedParams.permit(:project_type, :blubs1)

      expect(PermittedParams.new(params, user).project_type).to eq('blubs1' => 'blubs')

      PermittedParams.instance_variable_set(:@whitelisted_params, original_whitelisted)
    end

    it 'raises an argument error if key does not exist' do
      expect { PermittedParams.permit(:bogus_key) }.to raise_error ArgumentError
    end
  end

  describe '#project_type' do
    it 'should return name' do
      params = ActionController::Parameters.new(project_type: { 'name' => 'blubs' })

      expect(PermittedParams.new(params, user).project_type).to eq('name' => 'blubs')
    end

    it 'should return allows_association' do
      params = ActionController::Parameters.new(project_type: { 'allows_association' => '1' })

      expect(PermittedParams.new(params, user).project_type).to eq('allows_association' => '1')
    end

    it 'should return reported_project_status_ids' do
      params = ActionController::Parameters.new(project_type: { 'reported_project_status_ids' => ['1'] })

      expect(PermittedParams.new(params, user).project_type).to eq('reported_project_status_ids' => ['1'])
    end
  end

  describe '#project_type_move' do
    it 'should permit move_to' do
      params = ActionController::Parameters.new(project_type: { 'move_to' => '1' })

      expect(PermittedParams.new(params, user).project_type_move).to eq('move_to' => '1')
    end
  end

  describe '#timeline' do
    it 'should permit all acceptable options params and one name params' do
      acceptable_options_params = ["exist", "zoom_factor", "initial_outline_expansion", "timeframe_start",
        "timeframe_end", "columns", "project_sort", "compare_to_relative", "compare_to_relative_unit",
        "compare_to_absolute", "vertical_planning_elements", "exclude_own_planning_elements",
        "planning_element_status", "planning_element_types", "planning_element_responsibles",
        "planning_element_assignee", "exclude_reporters", "exclude_empty", "project_types",
        "project_status", "project_responsibles", "parents", "planning_element_time_types",
        "planning_element_time_absolute_one", "planning_element_time_absolute_two",
        "planning_element_time_relative_one", "planning_element_time_relative_one_unit",
        "planning_element_time_relative_two", "planning_element_time_relative_two_unit",
        "grouping_one_enabled", "grouping_one_selection", "grouping_one_sort", "hide_other_group"]

      acceptable_options_params_with_data = HashWithIndifferentAccess[acceptable_options_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(timeline: {'name' => 'my name', 'options' => acceptable_options_params_with_data})

      expect(PermittedParams.new(params, user).timeline).to eq({'name' => 'my name', 'options' => acceptable_options_params_with_data})
    end

    it 'should accept with no options' do
      params = ActionController::Parameters.new(timeline: {'name' => 'my name'})

      expect(PermittedParams.new(params, user).timeline).to eq({'name' => 'my name'})
    end
  end

  describe '#pref' do
    it 'should permit its withlisted params' do
      acceptable_params = [:hide_mail, :time_zone, :impaired,
                           :comments_sorting, :warn_on_leaving_unsaved,
                           :theme]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(pref: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).pref).to eq(acceptable_params_with_data)
    end
  end

  describe '#time_entry' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:hours, :comments, :work_package_id,
                            :activity_id, :spent_on]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      acceptable_params_with_data.merge!(custom_field_values: {
        '1' => 'foo',
        '2' => 'bar',
        '3' => 'baz'
      })

      params = ActionController::Parameters.new(time_entry: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).time_entry).to eq(acceptable_params_with_data)
    end

    it 'allows passing an empty HashWithIndifferentAccess (no time_entry)' do
      params = ActionController::Parameters.new

      expect(PermittedParams.new(params, user).time_entry).to eq({})
    end
  end

  describe '#news' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:title, :summary, :description]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(news: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).news).to eq(acceptable_params_with_data)
    end
  end

  describe '#comment' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:commented, :author, :comments]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(comment: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).comment).to eq(acceptable_params_with_data)
    end
  end

  describe '#watcher' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:watchable, :user, :user_id]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(watcher: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).watcher).to eq(acceptable_params_with_data)
    end
  end

  describe '#reply' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:content, :subject]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(reply: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).reply).to eq(acceptable_params_with_data)
    end
  end

  describe '#wiki' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:start_page]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(wiki: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).wiki).to eq(acceptable_params_with_data)
    end
  end

  describe '#reporting' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:reporting_to_project_id, :reported_project_status_id, :reported_project_status_comment]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(reporting: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).reporting).to eq(acceptable_params_with_data)
    end

    it 'allows an empty params hash' do
      params = ActionController::Parameters.new
      expect(PermittedParams.new(params, user).time_entry).to eq({})
    end
  end

  describe '#membership' do
    it 'should permit its whitelisted params' do
      acceptable_params_with_data = HashWithIndifferentAccess[project_id: '1', role_ids: [1,2,4]]

      params = ActionController::Parameters.new(membership: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).membership).to eq(acceptable_params_with_data)
    end
  end

  describe '#category' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:name, :assigned_to_id]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      params = ActionController::Parameters.new(category: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).category).to eq(acceptable_params_with_data)
    end
  end

  describe '#version' do
    it 'should permit its whitelisted params' do
      acceptable_params = [:name, :description, :effective_date, :due_date,
                           :start_date, :wiki_page_title, :status, :sharing,
                           :custom_field_value]

      acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

      acceptable_params_with_data.merge!(version_settings_attributes: {id: '1',
                                                                       display: '2',
                                                                       project_id: '3'})

      params = ActionController::Parameters.new(version: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).version).to eq(acceptable_params_with_data)
    end

    it 'allows an empty params hash' do
      params = ActionController::Parameters.new
      expect(PermittedParams.new(params, user).time_entry).to eq({})
    end
  end

  describe '#message' do
    describe 'with no instance passed' do
      it 'should permit its whitelisted params' do
        acceptable_params = [:subject, :content, :board_id]

        acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

        # Sticky and evil should not make it.
        params = ActionController::Parameters.new(message: acceptable_params_with_data.merge(evil: true, sticky: true))

        expect(PermittedParams.new(params, user).message).to eq(acceptable_params_with_data)
      end

      it 'allows an empty params hash' do
        params = ActionController::Parameters.new
        expect(PermittedParams.new(params, user).time_entry).to eq({})
      end
    end

    describe 'with instance passed' do
      it 'allows additional params for authorized users' do
        instance = double('message', project: double('project'))
        allow(user).to receive(:allowed_to?).with(:edit_messages, instance.project).and_return(true)

        acceptable_params = [:locked, :sticky]

        acceptable_params_with_data = HashWithIndifferentAccess[acceptable_params.map {|x| [x, 'value']}]

        params = ActionController::Parameters.new(message: acceptable_params_with_data)

        expect(PermittedParams.new(params, user).message(instance)).to eq(acceptable_params_with_data)
      end
    end
  end

  describe '#attachments' do
    it 'should permit its whitelisted params' do
      acceptable_params_with_data = HashWithIndifferentAccess[file: 'myfile',
                                     description: 'mydescription']

      params = ActionController::Parameters.new(attachments: acceptable_params_with_data)

      expect(PermittedParams.new(params, user).attachments).to eq(acceptable_params_with_data)
    end
  end

  describe '#project_types' do
    it 'should require type_ids within project' do
      params = ActionController::Parameters.new(project: { type_ids: ['1', '', '2'] })

      expect(PermittedParams.new(params, user).projects_type_ids).to eq([1, 2])
    end
  end

  describe '#color' do
    it 'should permit name' do
      params = ActionController::Parameters.new(color: { 'name' => 'blubs' })

      expect(PermittedParams.new(params, user).color).to eq('name' => 'blubs')
    end

    it 'should permit hexcode' do
      params = ActionController::Parameters.new(color: { 'hexcode' => '#fff' })

      expect(PermittedParams.new(params, user).color).to eq('hexcode' => '#fff')
    end
  end

  describe '#color_move' do
    it 'should permit move_to' do
      params = ActionController::Parameters.new(color: { 'move_to' => '1' })

      expect(PermittedParams.new(params, user).color_move).to eq('move_to' => '1')
    end
  end

  describe '#custom_field' do
    it 'should permit move_to' do
      params = ActionController::Parameters.new(custom_field: { 'editable' => '0', 'visible' => '0', 'filtered' => 42 })

      expect(PermittedParams.new(params, user).custom_field).to eq('editable' => '0', 'visible' => '0')
    end
  end

  describe '#planning_element_type' do
    it 'should permit move_to' do
      hash = { 'name' => 'blubs' }

      params = ActionController::Parameters.new(planning_element_type: hash)

      expect(PermittedParams.new(params, user).planning_element_type).to eq(hash)
    end

    it 'should permit in_aggregation' do
      hash = { 'in_aggregation' => '1' }

      params = ActionController::Parameters.new(planning_element_type: hash)

      expect(PermittedParams.new(params, user).planning_element_type).to eq(hash)
    end

    it 'should permit is_milestone' do
      hash = { 'is_milestone' => '1' }

      params = ActionController::Parameters.new(planning_element_type: hash)

      expect(PermittedParams.new(params, user).planning_element_type).to eq(hash)
    end

    it 'should permit is_default' do
      hash = { 'is_default' => '1' }

      params = ActionController::Parameters.new(planning_element_type: hash)

      expect(PermittedParams.new(params, user).planning_element_type).to eq(hash)
    end

    it 'should permit color_id' do
      hash = { 'color_id' => '1' }

      params = ActionController::Parameters.new(planning_element_type: hash)

      expect(PermittedParams.new(params, user).planning_element_type).to eq(hash)
    end
  end

  describe '#planning_element_type_move' do
    it 'should permit move_to' do
      hash = { 'move_to' => '1' }

      params = ActionController::Parameters.new(planning_element_type: hash)

      expect(PermittedParams.new(params, user).planning_element_type_move).to eq(hash)
    end
  end

  describe '#new_work_package' do
    it 'should permit subject' do
      hash = { 'subject' => 'blubs' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit description' do
      hash = { 'description' => 'blubs' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit start_date' do
      hash = { 'start_date' => '2013-07-08' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit due_date' do
      hash = { 'due_date' => '2013-07-08' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit assigned_to_id' do
      hash = { 'assigned_to_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit responsible_id' do
      hash = { 'responsible_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit type_id' do
      hash = { 'type_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit priority_id' do
      hash = { 'priority_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit parent_id' do
      hash = { 'parent_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit parent_id' do
      hash = { 'parent_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit fixed_version_id' do
      hash = { 'fixed_version_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit estimated_hours' do
      hash = { 'estimated_hours' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit done_ratio' do
      hash = { 'done_ratio' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit status_id' do
      hash = { 'status_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit category_id' do
      hash = { 'category_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it 'should permit watcher_user_ids when the user is allowed to add watchers' do
      project = double('project')

      allow(user).to receive(:allowed_to?).with(:add_work_package_watchers, project).and_return(true)

      hash = { 'watcher_user_ids' => ['1', '2'] }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package(project: project)).to eq(hash)
    end

    it 'should not return watcher_user_ids when the user is not allowed to add watchers' do
      project = double('project')

      allow(user).to receive(:allowed_to?).with(:add_work_package_watchers, project).and_return(false)

      hash = { 'watcher_user_ids' => ['1', '2'] }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package(project: project)).to eq({})
    end

    it 'should permit custom field values' do
      hash = { 'custom_field_values' => { '1' => '5' } }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it "should remove custom field values that do not follow the schema 'id as string' => 'value as string'" do
      hash = { 'custom_field_values' => { 'blubs' => '5', '5' => { '1' => '2' } } }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq({})
    end
  end

  describe '#update_work_package' do
    it 'should permit subject' do
      hash = { 'subject' => 'blubs' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit description' do
      hash = { 'description' => 'blubs' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit start_date' do
      hash = { 'start_date' => '2013-07-08' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit due_date' do
      hash = { 'due_date' => '2013-07-08' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit assigned_to_id' do
      hash = { 'assigned_to_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit responsible_id' do
      hash = { 'responsible_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit type_id' do
      hash = { 'type_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit priority_id' do
      hash = { 'priority_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit parent_id' do
      hash = { 'parent_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit parent_id' do
      hash = { 'parent_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit fixed_version_id' do
      hash = { 'fixed_version_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit estimated_hours' do
      hash = { 'estimated_hours' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit done_ratio' do
      hash = { 'done_ratio' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit lock_version' do
      hash = { 'lock_version' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit status_id' do
      hash = { 'status_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit category_id' do
      hash = { 'category_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit notes' do
      hash = { 'journal_notes' => 'blubs' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit attachments' do
      hash = { 'attachments' => [{ 'file' => 'djskfj', 'description' => 'desc' }] }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end

    it 'should permit time_entry if the user has the log_time permission' do
      hash = { 'time_entry' => { 'hours' => '5', 'activity_id' => '1', 'comments' => 'lorem' } }

      project = double('project')
      allow(user).to receive(:allowed_to?).with(:log_time, project).and_return(true)

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package(project: project)).to eq(hash)
    end

    it 'should not permit time_entry if the user lacks the log_time permission' do
      hash = { 'time_entry' => { 'hours' => '5', 'activity_id' => '1', 'comments' => 'lorem' } }

      project = double('project')
      allow(user).to receive(:allowed_to?).with(:log_time, project).and_return(false)

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package(project: project)).to eq({})
    end

    it 'should permit custom field values' do
      hash = { 'custom_field_values' => { '1' => '5' } }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq(hash)
    end

    it "should remove custom field values that do not follow the schema 'id as string' => 'value as string'" do
      hash = { 'custom_field_values' => { 'blubs' => '5', '5' => { '1' => '2' } } }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).new_work_package).to eq({})
    end
  end

  describe '#user' do
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

    [:user_update_as_admin, :user_create_as_admin].each do |method|
      describe method do
        it 'should permit nothing for a non-admin user' do
          # Hash with {'key' => 'key'} for all admin_permissions
          field_sample = { user: Hash[admin_permissions.zip(admin_permissions)] }

          params = ActionController::Parameters.new(field_sample)
          expect(PermittedParams.new(params, user).method(method).call(false, true)).to eq({})
        end

        admin_permissions.each do |field|
          it "should permit #{field}" do
            hash = { field => 'test' }
            params = ActionController::Parameters.new(user: hash)
            result = PermittedParams.new(params, admin).method(method).call(false, true)

            expect(result).to eq(field => 'test')
          end
        end

        context 'with no password change allowed' do
          it 'should not permit force_password_change' do
            hash = { 'force_password_change' => 'true' }
            params = ActionController::Parameters.new(user: hash)
            result = PermittedParams.new(params, admin).method(method).call(false, false)

            expect(result).to eq({})
          end
        end

        context 'with external authentication' do
          it 'should not permit auth_source_id' do
            hash = { 'auth_source_id' => 'true' }
            params = ActionController::Parameters.new(user: hash)
            result = PermittedParams.new(params, admin).method(method).call(true, true)

            expect(result).to eq({})
          end
        end

        it 'should permit custom field values' do
          hash = { 'custom_field_values' => { '1' => '5' } }

          params = ActionController::Parameters.new(user: hash)
          result = PermittedParams.new(params, admin).method(method).call(false, true)

          expect(result).to eq(hash)
        end

        it "should remove custom field values that do not follow the schema 'id as string' => 'value as string'" do
          hash = { 'custom_field_values' => { 'blubs' => '5', '5' => { '1' => '2' } } }

          params = ActionController::Parameters.new(user: hash)
          result = PermittedParams.new(params, admin).method(method).call(false, true)

          expect(result).to eq({})
        end
      end
    end

    describe '#user_update_as_admin' do
      it 'should permit a group_ids list' do
        hash = { 'group_ids' => ['1', '2'] }
        params = ActionController::Parameters.new(user: hash)

        expect(PermittedParams.new(params, admin).user_update_as_admin(false, false)).to eq(hash)
      end
    end

    describe '#user_create_as_admin' do
      it 'should not permit a group_ids list' do
        hash = { 'group_ids' => ['1', '2'] }
        params = ActionController::Parameters.new(user: hash)

        expect(PermittedParams.new(params, admin).user_create_as_admin(false, false)).to eq({})
      end
    end

    user_permissions = [
      'firstname',
      'lastname',
      'mail',
      'mail_notification',
      'language',
      'custom_fields',
    ]

    describe '#user' do
      user_permissions.each do |field|
        it "should permit #{field}" do
          hash = { field => 'test' }
          params = ActionController::Parameters.new(user: hash)

          expect(PermittedParams.new(params, admin).user).to eq(
            field => 'test'
          )
        end
      end

      (admin_permissions - user_permissions).each do |field|
        it "should not permit #{field} (admin-only)" do
          hash = { field => 'test' }
          params = ActionController::Parameters.new(user: hash)

          expect(PermittedParams.new(params, admin).user).to eq({})
        end
      end

      it 'should permit custom field values' do
        hash = { 'custom_field_values' => { '1' => '5' } }

        params = ActionController::Parameters.new(user: hash)

        expect(PermittedParams.new(params, admin).user).to eq(hash)
      end

      it "should remove custom field values that do not follow the schema 'id as string' => 'value as string'" do
        hash = { 'custom_field_values' => { 'blubs' => '5', '5' => { '1' => '2' } } }

        params = ActionController::Parameters.new(user: hash)

        expect(PermittedParams.new(params, admin).user).to eq({})
      end

      it 'should not allow identity_url' do
        hash = { 'identity_url'  => 'test_identity_url' }

        params = ActionController::Parameters.new(user: hash)

        expect(PermittedParams.new(params, admin).user).to eq({})
      end
    end
  end

  describe '#user_register_via_omniauth' do
    user_permissions = %w(login firstname lastname mail language)

    user_permissions.each do |field|
      it "should permit #{field}" do
        hash = { field => 'test' }
        params = ActionController::Parameters.new(user: hash)

        expect(PermittedParams.new(params, admin).user_register_via_omniauth).to eq(
          field => 'test')
      end
    end

    it 'should not allow identity_url' do
      hash = { 'identity_url'  => 'test_identity_url' }

      params = ActionController::Parameters.new(user: hash)

      expect(PermittedParams.new(params, admin).user_register_via_omniauth).to eq({})
    end
  end

  shared_context 'prepare params comparison' do
    let(:params_key) { (defined? hash_key) ? hash_key : attribute }
    let(:params) { ActionController::Parameters.new(params_key => hash) }

    subject { PermittedParams.new(params, user).send(attribute) }
  end

  shared_examples_for 'allows params' do
    include_context 'prepare params comparison'

    it { expect(subject).to eq(hash) }
  end

  shared_examples_for 'allows nested params' do
    let(:params_key) { (defined? hash_key) ? hash_key : attribute }
    let(:params) { ActionController::Parameters.new(params_key => { nested_key => hash }) }

    subject { PermittedParams.new(params, user).send attribute }

    it { expect(subject).to eq(hash) }
  end

  shared_examples_for 'forbids params' do
    include_context 'prepare params comparison'

    it { expect(subject).not_to eq(hash) }
  end

  shared_examples_for 'allows enumeration move params' do
    let(:hash) { {"2" =>{ 'move_to' => 'lower' }} }

    it_behaves_like 'allows params'
  end

  shared_examples_for 'allows move params' do
    let(:hash) { { 'move_to' => 'lower' }}

    it_behaves_like 'allows params'
  end

  shared_examples_for 'allows custom fields' do
    describe 'valid custom fields' do
      let(:hash) { {"1" => { 'custom_field_values' => { '1' => '5' } } }}

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

  describe '#enumerations' do
    let (:attribute) { :enumerations }

    describe 'name' do
      let(:hash) { {"1" => { 'name' => 'blubs' } }}

      it_behaves_like 'allows params'
    end

    describe 'active' do
      let(:hash) { {"1" => { 'active' => 'true' } }}

      it_behaves_like 'allows params'
    end

    describe 'is_default' do
      let(:hash) { {"1" => { 'is_default' => 'true' } }}

      it_behaves_like 'allows params'
    end

    describe 'reassign_to_id' do
      let(:hash) { {"1" => { 'reassign_to_id' => '1' } }}

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
