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

  require File.expand_path('../../spec_helper', __FILE__)

  describe Timeline do
    describe 'helper methods for creation' do
      describe 'available_responsibles' do
        it 'is sorted according to general setting' do
          ab = FactoryGirl.create(:user, :firstname => 'a', :lastname => 'b')
        ba = FactoryGirl.create(:user, :firstname => 'b', :lastname => 'a')
        t  = Timeline.new

        Setting.user_format = :firstname_lastname
        t.available_responsibles.should == [ab, ba]

        Setting.user_format = :lastname_firstname
        t.available_responsibles.should == [ba, ab]
      end
    end
  end
end
