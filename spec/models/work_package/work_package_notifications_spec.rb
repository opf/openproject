#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

##
# Tests that email notifications will be sent upon creating or changing a work package.
describe WorkPackage, type: :model do
  describe 'email notifications' do
    using_shared_fixtures :admin
    let(:user) { admin }
    let(:current_user) { FactoryBot.create :admin }
    let(:project) { FactoryBot.create :project }
    let!(:work_package) do
      FactoryBot.create :work_package,
                        author: user,
                        subject: 'I can see you',
                        project: project
    end

    context 'after creation' do
      it "are sent to the work package's author" do
        perform_enqueued_jobs
        mail = ActionMailer::Base.deliveries.detect { |m| m.subject.include? 'I can see you' }

        expect(mail).to be_present
      end

      context 'with email notifications disabled' do
        let(:user) { FactoryBot.create :admin, mail_notification: "none" }

        let(:project) do
          project = FactoryBot.create :project
          role = FactoryBot.create :role

          project.members.create principal: user, roles: [role], mail_notification: true

          project
        end

        it "are not sent to the work package's author" do
          mail = ActionMailer::Base.deliveries.detect { |m| m.subject.include? 'I can see you' }

          expect(mail).not_to be_present
        end
      end
    end

    describe 'after update' do
      before do
        work_package.update subject: 'the wind of change'
      end

      it "are sent to the work package's author" do
        perform_enqueued_jobs
        mail = ActionMailer::Base.deliveries.detect { |m| m.subject.include? 'the wind of change' }

        expect(mail).to be_present
      end
    end
  end
end
