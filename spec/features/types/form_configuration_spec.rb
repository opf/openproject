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

describe 'form configuration', type: :feature, js: true do
  let(:current_user) { FactoryGirl.create :admin }
  let(:type) { FactoryGirl.create :type}

  def checkbox_selector(attribute)
    ".type-form-conf-attribute[data-key=#{attribute}] .attribute-visibility input"
  end

  def attribute_handle_selector(attribute)
    "//*[@class='type-form-conf-attribute' and @data-key='#{attribute}']//*[@class='attribute-handle']"
  end

  before do
    allow(User).to receive(:current).and_return current_user

    visit edit_type_tab_path(id: type.id, tab: "form_configuration")
  end

  describe 'before update' do
    it 'attributes are in active group' do
      # the `version` attribute should initially be in a default group and thus
      # have 'default' visibility.
      expect(page).to have_selector(:xpath, "//*[@class='type-form-conf-attribute'][@data-key='version']/ancestor::*[@class='type-form-conf-group']")

      # per default the attribute `assignee` is active and not always visisble
      expect(page).to have_selector(:xpath, "//*[@class='type-form-conf-attribute'][@data-key='assignee']/ancestor::*[@class='type-form-conf-group']")
      expect(find(:css, checkbox_selector('assignee'))).not_to be_checked
    end
  end

  describe 'after update' do
    before do
      # change attribute groups and visibility

      # deactivate `version`:
      find(:xpath, attribute_handle_selector('version')).drag_to find("#type-form-conf-inactive-group .attributes")

      # change `assignee` to be always visible:
      find(:css, checkbox_selector('assignee')).set true

      # rename a group
      group_edit_selector = ".type-form-conf-group[data-original-key='people'] group-edit-in-place"
      find(group_edit_selector).click
      find(group_edit_selector + " input").set("persons")
      execute_script("angular.element('.type-form-conf-group input').blur()")
      # repition of the same command is a hack to blur the input
      execute_script("angular.element('.type-form-conf-group input').blur()")

      # create a new group and add an attribute
      # TODO
      # click_on 'Add group'
      # first("group-edit-in-place input").set("Populated group")
      # execute_script("angular.element('.type-form-conf-group input').blur()")
      # # repition of the same command is a hack to blur the input
      # execute_script("angular.element('.type-form-conf-group input').blur()")
      # drop_zone = first(".type-form-conf-group[data-key='people']")
      # find(:xpath, attribute_handle_selector('date')).drag_to drop_zone

      # first(".type-form-conf-group .attribute-visibility").click
      # create a group and keep it empty
      # TODO

      # delete a group
      # TODO
      click_on 'Save'
    end

    it 'attributes are in their new groups and with correct visibility' do
      # `version` is now in inactives group
      expect(page).to have_selector(:xpath, "//*[@class='type-form-conf-attribute'][@data-key='version']/ancestor::*[@id='type-form-conf-inactive-group']")

      # `assignee` shall have the checkbox set to true
      expect(find(:css, checkbox_selector('assignee'))).to be_checked

      # the former "people" group shall be "persons" now
      expect(page).to have_selector(".type-form-conf-group[data-original-key='persons']")
    end
  end
end
