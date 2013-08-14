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

describe "Journalized Objects" do
  before(:each) do
    @type ||= FactoryGirl.create(:type_feature)
    @project ||= FactoryGirl.create(:project_with_types)
    @current = FactoryGirl.create(:user, :login => "user1", :mail => "user1@users.com")
    User.stub!(:current).and_return(@current)
  end

  it 'should work with documents' do
    @document ||= FactoryGirl.create(:document)

    initial_journal = @document.journals.first
    recreated_journal = @document.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end
end
