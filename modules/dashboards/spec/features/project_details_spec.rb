#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

require_relative '../support/pages/dashboard'

describe 'Project details widget on dashboard', type: :feature, js: true do
  let!(:version_cf) { FactoryBot.create(:version_project_custom_field) }
  let!(:bool_cf) { FactoryBot.create(:bool_project_custom_field) }
  let!(:user_cf) { FactoryBot.create(:user_project_custom_field) }
  let!(:int_cf) { FactoryBot.create(:int_project_custom_field) }
  let!(:float_cf) { FactoryBot.create(:float_project_custom_field) }
  let!(:text_cf) { FactoryBot.create(:text_project_custom_field) }
  let!(:string_cf) { FactoryBot.create(:string_project_custom_field) }
  let!(:date_cf) { FactoryBot.create(:date_project_custom_field) }

  let(:system_version) { FactoryBot.create(:version, sharing: 'system') }

  let!(:project) do
    FactoryBot.create(:project).tap do |p|
      p.add_member(other_user, [role])

      p.send(:"custom_field_#{int_cf.id}=", 5)
      p.send(:"custom_field_#{bool_cf.id}=", true)
      p.send(:"custom_field_#{version_cf.id}=", system_version)
      p.send(:"custom_field_#{float_cf.id}=", 4.5)
      p.send(:"custom_field_#{text_cf.id}=", 'Some **long** text')
      p.send(:"custom_field_#{string_cf.id}=", 'Some small text')
      p.send(:"custom_field_#{date_cf.id}=", Date.today)
      p.send(:"custom_field_#{user_cf.id}=", other_user)

      p.save!(validate: false)
    end
  end

  let(:permissions) do
    %i[view_dashboards
       manage_dashboards]
  end

  let(:role) do
    FactoryBot.create(:role, permissions: permissions)
  end

  let(:user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:other_user) do
    FactoryBot.create(:user)
  end
  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard_page.visit!
  end

  it 'can add the widget and see the description in it' do
    dashboard_page.add_widget(1, 1, :within, "Project details")

    sleep(0.1)

    # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
    details_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    within(details_widget.area) do
      expect(page)
        .to have_content("#{int_cf.name}\n5")
      expect(page)
        .to have_content("#{bool_cf.name}\nyes")
      expect(page)
        .to have_content("#{version_cf.name}\n#{system_version.name}")
      expect(page)
        .to have_content("#{float_cf.name}\n4.5")
      expect(page)
        .to have_content("#{text_cf.name}\nSome long text")
      expect(page)
        .to have_content("#{string_cf.name}\nSome small text")
      expect(page)
        .to have_content("#{date_cf.name}\n#{Date.today.strftime('%m/%d/%Y')}")
      expect(page)
        .to have_content("#{user_cf.name}\n#{user.name.split.map(&:first).join}#{user.name}")
    end
  end
end
