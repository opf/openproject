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

describe WorkPackage do
  describe ActionMailer::Base do
    let(:user_1) { FactoryGirl.create(:user,
                                      mail: "dlopper@somenet.foo") }
    let(:user_2) { FactoryGirl.create(:user,
                                      mail: "jsmith@somenet.foo") }
    let(:work_package) { FactoryGirl.build(:work_package) }

    before do
      ActionMailer::Base.deliveries.clear

      work_package.stub(:recipients).and_return([user_1.mail])
      work_package.stub(:watcher_recipients).and_return([user_2.mail])

      work_package.save
    end

    subject { ActionMailer::Base.deliveries.size }

    it { should eq(2) }

    context "stale object" do
      before do
        wp = WorkPackage.find(work_package.id)

        wp.subject = "Subject update"
        wp.save!

        ActionMailer::Base.deliveries.clear

        work_package.subject = "A different subject update"
        work_package.save! rescue nil
      end

      it { should eq(0) }
    end

    context "no notification" do
      before do
        ActionMailer::Base.deliveries.clear

        WorkPackageObserver.instance.send_notification = false

        work_package.save!
      end

      it { should eq(0) }
    end
  end
end
