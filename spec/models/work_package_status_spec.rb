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

describe WorkPackage do
  describe '- Relations ' do
    describe '#workpackage status' do
      it 'can read planning_elements w/ the help of the has_many association' do
        status       = FactoryGirl.create(:issue_status)
        work_package = FactoryGirl.create(:work_package,
                                          :status_id => status.id)

        WorkPackage.where(status_id: status.id).count.should == 1
        WorkPackage.where(status_id: status.id).first.should == work_package
      end
    end
  end
end
