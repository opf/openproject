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
require_relative 'support/pages/cost_report_page'

describe "updating a cost report's cost type", type: :feature, js: true do
  let(:project) { FactoryBot.create :project_with_types }
  let(:user) do
    FactoryBot.create(:admin).tap do |user|
      project.add_member! user, FactoryBot.create(:role)
    end
  end

  let(:cost_type) do
    FactoryBot.create :cost_type, name: 'Post-war', unit: 'cap', unit_plural: 'caps'
  end

  let!(:cost_entry) do
    FactoryBot.create :cost_entry, user: user, project: project, cost_type: cost_type
  end

  let(:report_page) { ::Pages::CostReportPage.new project }

  before do
    login_as(user)
  end

  it 'works' do
    report_page.visit!
    report_page.save(as: 'My Query', public: true)

    report_page.switch_to_type cost_type.name

    click_on "Save"

    click_on "My Query"

    option = all("[name=unit]").last

    expect(option).to be_checked
    expect(option.value).to eq cost_type.id.to_s
  end
end
