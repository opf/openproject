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

describe 'filter me value', js: true do
  let(:status) { FactoryBot.create :default_status}
  let!(:priority) { FactoryBot.create :default_priority }
  let(:project) { FactoryBot.create :project, public: true }
  let(:role) { FactoryBot.create :existing_role, permissions: [:view_work_packages] }
  let(:admin) { FactoryBot.create :admin }
  let(:user) { FactoryBot.create :user }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  before do
    login_as admin
    project.add_member! admin, role
    project.add_member! user, role
  end

  describe 'assignee' do
    let(:wp_admin) { FactoryBot.create :work_package, status: status, project: project, assigned_to: admin }
    let(:wp_user) { FactoryBot.create :work_package, status: status, project: project, assigned_to: user }

    context 'as anonymous', with_settings: { login_required?: false } do
      let(:assignee_query) do
        query = FactoryBot.create(:query,
                                   name: 'Assignee Query',
                                   project: project,
                                   user: user)

        query.add_filter('assigned_to_id', '=', ['me'])
        query.save!(validate: false)

        query
      end

      it 'shows an error visiting a query with a me value' do
        wp_table.visit_query assignee_query
        wp_table.expect_notification(type: :error,
                                     message: I18n.t('js.work_packages.faulty_query.description'))
      end
    end

    context 'logged in' do
      before do
        wp_admin
        wp_user

        login_as(admin)
      end

      it 'shows the one work package filtering for myself' do
        wp_table.visit!
        wp_table.expect_work_package_listed(wp_admin, wp_user)

        # Add and save query with me filter
        filters.open
        filters.remove_filter 'status'
        filters.add_filter_by('Assignee', 'is', 'me')

        wp_table.ensure_work_package_not_listed!(wp_user)
        wp_table.expect_work_package_listed(wp_admin)

        wp_table.save_as('Me query')
        loading_indicator_saveguard

        # Expect correct while saving
        wp_table.expect_title 'Me query'
        query = Query.last
        expect(query.filters.first.values).to eq ['me']
        filters.expect_filter_by('Assignee', 'is', 'me')

        # Revisit query
        wp_table.visit_query query
        wp_table.ensure_work_package_not_listed!(wp_user)
        wp_table.expect_work_package_listed(wp_admin)

        filters.open
        filters.expect_filter_by('Assignee', 'is', 'me')

        # Expect new work packages receive assignee
        split_screen = wp_table.create_wp_by_button wp_user.type
        subject = split_screen.edit_field :subject
        subject.set_value 'foobar'
        subject.submit_by_enter

        split_screen.expect_and_dismiss_notification message: 'Successful creation.'

        wp = WorkPackage.last
        expect(wp.assigned_to_id).to eq(admin.id)
      end
    end
  end

  describe 'custom_field of type user' do
    let(:custom_field) do
      FactoryBot.create(
        :work_package_custom_field,
        name: 'CF user',
        field_format: 'user',
        is_required: false
      )
    end
    let(:type_task) { FactoryBot.create(:type_task, custom_fields: [custom_field]) }
    let(:project) do
      FactoryBot.create(:project,
                         types: [type_task],
                         work_package_custom_fields: [custom_field])
    end

    let(:cf_accessor) { "cf_#{custom_field.id}" }
    let(:cf_accessor_frontend) { "customField#{custom_field.id}" }
    let(:wp_admin) do
      FactoryBot.create :work_package,
                         type: type_task,
                         project: project,
                         custom_field_values: { custom_field.id => admin.id }
    end

    let(:wp_user) do
      FactoryBot.create :work_package,
                         type: type_task,
                         project: project,
                         custom_field_values: { custom_field.id => user.id }
    end

    context 'as anonymous', with_settings: { login_required?: false } do
      let(:assignee_query) do
        query = FactoryBot.create(:query,
                                   name: 'CF user Query',
                                   project: project,
                                   user: user)

        query.add_filter(cf_accessor, '=', ['me'])
        query.save!(validate: false)

        query
      end

      it 'shows an error visiting a query with a me value' do
        wp_table.visit_query assignee_query
        wp_table.expect_notification(type: :error,
                                     message: I18n.t('js.work_packages.faulty_query.description'))
      end
    end

    context 'logged in' do
      before do
        wp_admin
        wp_user

        login_as(admin)
      end

      it 'shows the one work package filtering for myself' do
        wp_table.visit!
        wp_table.expect_work_package_listed(wp_admin, wp_user)

        # Add and save query with me filter
        filters.open
        filters.remove_filter 'status'
        filters.add_filter_by('CF user', 'is', 'me', cf_accessor_frontend)

        wp_table.ensure_work_package_not_listed!(wp_user)
        wp_table.expect_work_package_listed(wp_admin)

        wp_table.save_as('Me query')
        loading_indicator_saveguard

        # Expect correct while saving
        wp_table.expect_title 'Me query'
        query = Query.last
        expect(query.filters.first.values).to eq ['me']
        filters.expect_filter_by('CF user', 'is', 'me', cf_accessor_frontend)

        # Revisit query
        wp_table.visit_query query
        wp_table.ensure_work_package_not_listed!(wp_user)
        wp_table.expect_work_package_listed(wp_admin)

        filters.open
        filters.expect_filter_by('CF user', 'is', 'me', cf_accessor_frontend)
      end
    end
  end
end
