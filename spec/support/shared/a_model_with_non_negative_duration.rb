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

shared_examples_for "a model with non-negative duration" do
  # it is assumed, that planning elements start on start_date 00:01 and end
  # on due_date 23:59. Therefore, if start_date and due_date are on the very
  # same day, the duration should be 1.
  describe 'duration' do
    describe 'when start date == end date' do
      it 'is 1' do
        subject.start_date = Date.today
        subject.due_date   = Date.today
        subject.duration.should == 1
      end
    end

    describe 'when end date > start date' do
      it 'is the difference between end date and start date plus one day' do
        subject.start_date = 5.days.ago.to_date
        subject.due_date   = Date.today
        subject.duration.should == 6
      end
    end

    describe 'when start date > end date' do
      it 'is 1' do
        subject.start_date = Date.today
        subject.due_date   = 5.days.ago.to_date
        subject.duration.should == 1
      end
    end
  end
end
