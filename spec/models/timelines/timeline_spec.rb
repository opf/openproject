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

require File.expand_path('../../../spec_helper', __FILE__)

describe Timelines::Timeline do
  let(:timeline) { Timelines::Timeline.new }

  describe 'helper methods for creation' do
    describe 'available_responsibles' do
      it 'is sorted according to general setting' do
        ab = FactoryGirl.create(:user, :firstname => 'a', :lastname => 'b')
        ba = FactoryGirl.create(:user, :firstname => 'b', :lastname => 'a')

        Setting.user_format = :firstname_lastname
        timeline.available_responsibles.should == [ab, ba]

        Setting.user_format = :lastname_firstname
        timeline.available_responsibles.should == [ba, ab]
      end

      it 'should not return the anonymous user' do
        anonymous = FactoryGirl.create(:anonymous)

        timeline.available_responsibles.should be_empty
      end

      it 'should not return the locked users' do
        user = FactoryGirl.create(:user, :status => User::STATUS_LOCKED)

        timeline.available_responsibles.should be_empty
      end

      it 'should return a registered users' do
        user = FactoryGirl.create(:user, :status => User::STATUS_REGISTERED)

        timeline.available_responsibles.should == [user]
      end
    end
  end
end
