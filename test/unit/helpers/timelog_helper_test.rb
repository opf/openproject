#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../test_helper', __FILE__)

class TimelogHelperTest < HelperTestCase
  include TimelogHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper

  fixtures :projects, :roles, :enabled_modules, :users,
                      :repositories, :changesets,
                      :trackers, :issue_statuses, :issues, :versions, :documents,
                      :wikis, :wiki_pages, :wiki_contents,
                      :boards, :messages,
                      :attachments,
                      :enumerations

  def setup
    super
  end

  def test_activities_collection_for_select_options_should_return_array_of_activity_names_and_ids
    activities = activity_collection_for_select_options
    assert activities.include?(["Design", 9])
    assert activities.include?(["Development", 10])
  end

  def test_activities_collection_for_select_options_should_not_include_inactive_activities
    activities = activity_collection_for_select_options
    assert !activities.include?(["Inactive Activity", 14])
  end

  def test_activities_collection_for_select_options_should_use_the_projects_override
    project = Project.find(1)
    override_activity = TimeEntryActivity.create!({:name => "Design override", :parent => TimeEntryActivity.find_by_name("Design"), :project => project})

    activities = activity_collection_for_select_options(nil, project)
    assert !activities.include?(["Design", 9]), "System activity found in: " + activities.inspect
    assert activities.include?(["Design override", override_activity.id]), "Override activity not found in: " + activities.inspect
  end
end
