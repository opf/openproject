# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

class MyRSpecExampleMailer < ApplicationMailer
  default from: "openproject@example.com",
          subject: "Welcome to OpenProject"

  def welcome_email
    user = params[:user]
    mail(to: user) do |format|
      format.text { render plain: "Welcome!" }
      format.html { render html: "<h1>Welcome!</h1>".html_safe }
    end
  end

  def welcome2(user)
    mail(to: user) do |format|
      format.text { render plain: "Welcome!" }
      format.html { render html: "<h1>Welcome!</h1>".html_safe }
    end
  end
end

RSpec.describe Mails::MailerJob do
  subject { described_class.new }

  it "is used to send emails when calling .deliver_later on a mailer" do
    user = create(:user, mail: "user@example.com")
    job = MyRSpecExampleMailer.with(user:).welcome_email.deliver_later
    expect(job).to be_an_instance_of(described_class)
    expect(enqueued_jobs).to contain_exactly(a_hash_including("job_class" => described_class.name))
    enqueued_job = enqueued_jobs.first

    perform_enqueued_jobs
    # job has been performed
    expect(performed_jobs).to contain_exactly(enqueued_job)
    # there are no more jobs
    expect(enqueued_jobs).to be_empty
  end

  it "retries sending email on StandardError" do
    user = "Will raise ArgumentError because ApplicationMailer expect a User instance as recipient"
    MyRSpecExampleMailer.with(user:).welcome_email.deliver_later
    expect(enqueued_jobs).to contain_exactly(a_hash_including("job_class" => "Mails::MailerJob",
                                                              "executions" => 0,
                                                              "exception_executions" => {}))

    # let's execute the mailer job
    job1 = enqueued_jobs.first
    perform_enqueued_jobs

    # job has been performed, but has encountered an error
    expect(performed_jobs).to contain_exactly(job1)
    expect(job1).to include("exception_executions" => { "[StandardError]" => 1 })

    # and it is being retried: another identical job is queued with an increased execution count
    expect(enqueued_jobs).to contain_exactly(a_hash_including("job_class" => "Mails::MailerJob",
                                                              "executions" => 1,
                                                              "exception_executions" => { "[StandardError]" => 1 }))

    # we can run this retried job, it will be performed, fail again, and enqueue another retry job again
    job2 = enqueued_jobs.first
    perform_enqueued_jobs
    expect(performed_jobs).to contain_exactly(job1, job2)
    expect(job2).to include("exception_executions" => { "[StandardError]" => 2 })
    expect(enqueued_jobs).to contain_exactly(a_hash_including("job_class" => "Mails::MailerJob",
                                                              "executions" => 2,
                                                              "exception_executions" => { "[StandardError]" => 2 }))

    # and so on...
  end
end
