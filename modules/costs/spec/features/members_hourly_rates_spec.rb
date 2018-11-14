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

describe 'hourly rates on a member', type: :feature, js: true do
  let(:project) { FactoryBot.build :project }
  let(:user) { FactoryBot.create :admin, member_in_project: project,
                                          member_through_role: [FactoryBot.create(:role)] }
  let(:member) { Member.find_by(project: project, user: user) }

  def view_rates
    visit edit_user_path(user, tab: 'rates')
  end

  def view_project_members
    visit project_members_path(project)
  end

  def expect_current_rate_in_members_table(amount)
    view_project_members

    expect(page).to have_selector("#member-#{member.id} .currency", text: amount)
  end

  def add_rate(date: nil, rate:)
    expect(page).to have_selector(".add-row-button")
    all("tr[id^='user_new_rate_attributes_'] .delete-row-button").each(&:click)
    click_link_or_button 'Add rate'

    within "tr[id^='user_new_rate_attributes_']" do
      fill_in 'Valid from', with: date.strftime('%Y-%m-%d') if date
      fill_in 'Rate', with: rate
    end

    find('.ui-datepicker-close').click rescue nil
  end

  def change_rate_date(from:, to:)
    input = find("table.rates .date[value='#{from.strftime('%Y-%m-%d')}']")
    input.set(to.strftime('%Y-%m-%d'))

    find('.ui-datepicker-close').click rescue nil

    # Without this, the opening Datepicker seems to revert the result???
    sleep(1)
  end

  before do
    project.save!
    allow(User).to receive(:current).and_return user
  end

  it 'displays always the currently active rate' do
    expect_current_rate_in_members_table('0.00 EUR')

    click_link('0.00 EUR')

    add_rate(date: Date.today, rate: 10)

    click_button 'Save'

    expect_current_rate_in_members_table('10.00 EUR')

    click_link('10.00 EUR')

    add_rate(date: 3.days.ago, rate: 20)

    click_button 'Save'

    expect_current_rate_in_members_table('10.00 EUR')

    click_link('10.00 EUR')

    change_rate_date(from: Date.today, to: 5.days.ago)

    click_button 'Save'

    expect_current_rate_in_members_table('20.00 EUR')
  end
end
