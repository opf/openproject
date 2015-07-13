#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

When(/^I open the modal window for the story "(.*?)"$/) do |subject|
  story = Story.find_by_subject(subject)

  within("#story_#{story.id}") do
    click_link(story.id)
  end
end

When(/^I click on the link for the story "(.*?)"$/) do |subject|
  story = Story.find_by_subject(subject)

  within("#story_#{story.id}") do
    click_link(story.id)
  end
end

When(/^I ctrl-click on the link for the story "(.*?)"$/) do |subject|
  story = Story.find_by_subject(subject)

  within("#story_#{story.id}") do
    link = find(:link, story.id)
    ctrl_click(link)
  end
end

When(/^I switch the modal window into edit mode$/) do
  browser = page.driver.browser
  browser.switch_to.frame('modalIframe')
  within('#content > .action_menu_specific') do
    click_link('Update')
  end
  safeguard_backlogs_modal_in_edit_mode
end

And(/^I switch out of the modal$/) do
  browser = page.driver.browser
  browser.switch_to.default_content
end

def safeguard_backlogs_modal_in_edit_mode
  find_field('work_package[description]')
end
