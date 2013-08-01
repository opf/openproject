#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Given(/^the work package "(.*?)" has the following changesets:$/) do |subject, table|
  wp = WorkPackage.find_by_subject!(subject)

  repo = wp.project.repository

  wp_changesets = table.hashes.map do |row|
    FactoryGirl.build(:changeset, row.merge({:repository => repo}))
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
        displayed_changeset.has_selector?('a', :text => I18n.t(:label_revision_id,
                                                               :value => row[:revision])))) &&
      (row[:comments] ||
       (row[:comments] &&
        displayed_changeset.has_selector?('', :text => row[:comments])))
    end.should be_true
  end
end

Then(/^I should not be presented changesets$/) do
  should_not have_selector('#work_package-changesets .changeset')
end
