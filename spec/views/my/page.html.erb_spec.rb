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

require 'spec_helper'

describe 'my/page' do
  let(:project)    { FactoryGirl.create :valid_project }
  let(:user)       { FactoryGirl.create :admin, :member_in_project => project }
  let(:issue)      { FactoryGirl.create :issue, :project => project, :author => user }
  let(:time_entry) { FactoryGirl.create :time_entry,
                                        :project => project,
                                        :user => user,
                                        :work_package => issue,
                                        :hours => 1}

  before do
    assign(:user, user)
    time_entry.spent_on = Date.today
    time_entry.save!
  end

  it 'renders the timelog block' do
    assign :blocks, {'top' => ['timelog'], 'left' => [], 'right' => []}

    render

    assert_select 'tr.time-entry td.subject' do |td|
      td.should have_link("#{issue.type.name} ##{issue.id}", :href => work_package_path(issue))
    end
  end
end
