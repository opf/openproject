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

describe 'Wysiwyg work package user mentions',
         type: :feature, js: true do
  let!(:user) { FactoryBot.create :admin }
  let!(:user2) { FactoryBot.build(:user, firstname: 'Foo', lastname: 'Bar', member_in_project: project) }
  let!(:group) { FactoryBot.create(:group, firstname: 'Foogroup', lastname: 'Foogroup') }
  let!(:group_role) { FactoryBot.create(:role) }
  let!(:group_member) do
    FactoryBot.create(:member,
                      principal: group,
                      project: project,
                      roles: [group_role])
  end
  let(:project) { FactoryBot.create(:project, enabled_module_names: %w[work_package_tracking]) }
  let!(:work_package) { FactoryBot.create(:work_package, subject: 'Foobar', project: project) }

  let(:wp_page) { ::Pages::FullWorkPackage.new work_package, project }
  let(:editor) { ::Components::WysiwygEditor.new }

  let(:selector) { '.work-packages--activity--add-comment' }
  let(:comment_field) do
    TextEditorField.new wp_page,
                        'comment',
                        selector: selector
  end

  before do
    login_as(user)
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it 'can autocomplete users and groups' do
    comment_field.activate!

    comment_field.clear with_backspace: true
    comment_field.input_element.send_keys("@Foo")
    expect(page).to have_selector('.mention-list-item', text: user2.name)
    expect(page).to have_selector('.mention-list-item', text: group.name)

    page.find('.mention-list-item', text: user2.name).click
    sleep 2

    retry_block do
      comment_field.submit_by_click if comment_field.active?
      page.find('a.user-mention', text: 'Foo Bar')
    end

    comment_field.activate!
    comment_field.clear with_backspace: true
    comment_field.input_element.send_keys(" @Foo")
    expect(page).to have_selector('.mention-list-item', text: user2.name)
    expect(page).to have_selector('.mention-list-item', text: group.name)

    page.find('.mention-list-item', text: group.name).click
    sleep 2

    retry_block do
      comment_field.submit_by_click if comment_field.active?
      page.find('span.user-mention', text: 'Foogroup')
    end
  end
end
