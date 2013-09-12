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
  describe :watcher do
    let(:user) { FactoryGirl.create(:user) }
    let(:project) { FactoryGirl.create(:project) }
    let(:role) { FactoryGirl.create(:role,
                                    permissions: [:view_work_packages]) }
    let(:project_member) { FactoryGirl.create(:member,
                                              project: project,
                                              principal: user,
                                              roles: [role]) }
    let(:work_package) { FactoryGirl.create(:work_package,
                                            project: project) }

    context :recipients do
      let(:watcher) { Watcher.new(watchable: work_package,
                                  user: user) }


      before do
        project_member

        watcher.save!

        role.remove_permission! :view_work_packages

        work_package.reload
      end

      context :watcher do
        subject { work_package.watched_by?(user) }

        it { should be_true }
      end

      context :recipients do
        subject { work_package.watcher_recipients }

        it { should_not include(user.mail) }
      end
    end
  end
end
