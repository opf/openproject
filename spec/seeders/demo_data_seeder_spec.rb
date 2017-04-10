#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'seeds' do
  it 'create the demo data' do
    perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    begin
      # Avoid asynchronous DeliverWorkPackageCreatedJob
      Delayed::Worker.delay_jobs = false

      expect{ BasicDataSeeder.new.seed! }.not_to raise_error
      expect{ AdminUserSeeder.new.seed! }.not_to raise_error
      expect{ DemoDataSeeder.new.seed! }.not_to raise_error

      expect(User.where(admin: true).count).to eq 1
      expect(Project.count).to eq 1
      expect(WorkPackage.count).to eq 7
      expect(Wiki.count).to eq 0
      expect(Query.count).to eq 6
    ensure
      ActionMailer::Base.perform_deliveries = perform_deliveries
    end
  end
end
