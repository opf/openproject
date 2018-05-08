#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
