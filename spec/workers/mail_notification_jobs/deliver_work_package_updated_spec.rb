#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
require 'workers/mail_notification_jobs/shared_examples'

describe DeliverWorkPackageUpdatedJob, type: :model do
  let(:work_package) do
    FactoryGirl.create(:work_package).tap do |wp|
      wp.subject = mail_subject
      wp.save # create journal
    end
  end

  let(:current_user) { FactoryGirl.create :user }
  let(:journal)      { work_package.journals.last }
  let(:job)          { DeliverWorkPackageUpdatedJob.new user.id, journal.id, current_user.id }

  it_behaves_like 'a mail notification job' do
    context 'with journal not found' do
      let(:mail_subject) { 'no journal found! :/' }

      before do
        journal.destroy
      end

      it_behaves_like 'job cannot find record'
    end

    context 'with current user not found' do
      let(:mail_subject) { 'current user not found! :x' }

      before do
        current_user.destroy
      end

      it_behaves_like 'job cannot find record'
    end
  end
end
