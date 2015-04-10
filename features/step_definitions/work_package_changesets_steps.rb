#-- encoding: UTF-8
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

Given(/^the work package "(.*?)" has the following changesets:$/) do |subject, table|
  wp = WorkPackage.find_by_subject!(subject)

  repo = wp.project.repository

  wp_changesets = table.hashes.map do |row|
    FactoryGirl.build(:changeset, row.merge(repository: repo))
  end

  wp.changesets = wp_changesets
end

Then(/^I should see the following changesets:$/) do |table|
  displayed_changesets = all('#work_package-changesets .changeset')

  unless (unsupported = table.headers - ['revision', 'comments']).empty?
    raise ArgumentError, "#{unsupported.join(', ')} is unsupported. But you can change that."
  end

  table.hashes.each do |row|
    displayed_changesets.any? do |displayed_changeset|
      (!row[:revision] ||
       (row[:revision] &&
        displayed_changeset.has_selector?('a', text: I18n.t(:label_revision_id,
                                                            value: row[:revision])))) &&
        (row[:comments] ||
         (row[:comments] &&
          displayed_changeset.has_selector?('', text: row[:comments])))
    end.should be_truthy
  end
end

Then(/^I should not be presented changesets$/) do
  should_not have_selector('#work_package-changesets .changeset')
end
