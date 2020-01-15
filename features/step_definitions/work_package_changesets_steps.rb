#-- encoding: UTF-8
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

Given(/^the work package "(.*?)" has the following changesets:$/) do |subject, table|
  wp = WorkPackage.find_by!(subject: subject)

  repo = wp.project.repository

  wp_changesets = table.hashes.map { |row|
    FactoryBot.build(:changeset, row.merge(repository: repo))
  }

  wp.changesets = wp_changesets
end

Then(/^I should see the following changesets:$/) do |table|
  unless (unsupported = table.headers - ['revision', 'comments']).empty?
    raise ArgumentError, "#{unsupported.join(', ')} is unsupported. But you can change that."
  end

  table.hashes.each do |row|
    # this will only work with one revision as we do not have proper markup
    # to identify different changesets
    within('.work-package-details-activities-list .revision-activity--revision-link') do
      expect(page).to have_content("committed revision #{row[:revision]}")
    end
  end
end

Then(/^I should not be presented changesets$/) do
  expect(page)
    .not_to have_selector('.work-package-details-activities-list .revision-activity--revision-link')
end
