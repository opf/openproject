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

describe WorkPackagesController, type: :controller do
  let(:user)    { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :public_project }

  before do
    allow(User).to receive(:current).and_return user
    expect(controller).to receive(:authorize).and_return(true)
  end

  around(:each) do |example|
    ##
    # In production mode jobs are naturally delayed.
    # They are not in test mode, however.
    # Since this is supposed to test actual production behaviour we
    # enable delayed jobs for this suite. Further comments below.
    begin
      Delayed::Worker.delay_jobs = true
      example.run
    ensure
      Delayed::Worker.delay_jobs = false
    end
  end

  describe 'create' do
    let(:work_package) { WorkPackage.find_by_subject 'genesis' }
    let(:priority)     { FactoryGirl.create :priority }
    let(:response)     { post 'create', params }
    let(:status)       { FactoryGirl.create :status }

    let(:params) do
      {
        project_id: project.id,
        work_package: {
          subject: 'genesis',
          status_id: status.id,
          priority_id: priority.id
        }
      }
    end

    let(:job) do
      # Find the enqueued job responsible for sending the notification
      # for the creation of the work package.
      Delayed::Job.all.map(&:payload_object).detect do |job|
        if job.is_a? DeliverWorkPackageCreatedJob
          job.send(:work_package) == work_package
        end
      end
    end

    describe 'with working email configuration' do
      before do
        response
      end

      it 'should redirect to the created work package' do
        redirect_to(work_package_path(work_package))
      end

      it 'enqueues a mail delivery job' do
        expect(job).to be_present
      end
    end

    ##
    # [regression test]
    #
    # Checks that work package creation does not lead to 500 responses
    # when the email configuration is broken as it did previously.
    # For this test to work delayed job has to actually delay the jobs
    # otherwise it will fail due to the exception raised in the job.
    #
    # Which is precisely the error that was fixed. Sending emails
    # after work package creation was performed in the context of the request.
    # This lead to an internal server error when sending the emails failed.
    # The fix moved that into a delayed job which can fail and which can be rescheduled.
    describe 'with broken email configuration' do
      before do
        allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(SocketError)

        response
      end

      it 'should not result in an internal server error' do
        expect(response.status).not_to eq 500
      end

      it 'should redirect to show' do
        expect(response).to redirect_to(work_package_path(work_package))
      end

      describe 'notification job' do
        it 'is enqueued' do
          expect(job).to be_present
        end

        it 'fails' do
          expect { job.perform }.to raise_error(SocketError)
        end
      end
    end
  end
end
