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

RSpec.describe ApplicationJob do
  class JobMock < ApplicationJob
    def initialize(callback)
      @callback = callback
    end

    def perform
      @callback.call
    end
  end

  describe "resets request store" do
    it "resets request store on each perform" do
      job = JobMock.new(-> do
        expect(RequestStore[:test_value]).to be_nil
        RequestStore[:test_value] = 42
      end)

      RequestStore[:test_value] = "my value"
      expect { job.perform_now }.not_to change { RequestStore[:test_value] }

      RequestStore[:test_value] = "my value2"
      expect { job.perform_now }.not_to change { RequestStore[:test_value] }

      expect(RequestStore[:test_value]).to eq "my value2"
    end
  end

  describe "email configuration" do
    let(:ports) { [] }

    before do
      # pick a random job to test if the settings are updated
      allow_any_instance_of(Principals::DeleteJob).to receive(:perform) do
        ports << ActionMailer::Base.smtp_settings[:port]
      end
    end

    it "is reloaded for each job" do
      # the email delivery method has to be smtp for the settings to be reloaded
      Setting.email_delivery_method = :smtp

      Principals::DeleteJob.perform_now nil

      expect(ports).not_to be_empty
      expect(ports.last).not_to be 42

      # We have to change the time here for Setting.settings_updated_at to actually be different from before
      # since this is of course all running within the same second.
      Timecop.travel(1.second.from_now) do
        # While we're in the worker here, this simulates another process changing the setting.
        Setting.create!(name: "smtp_port", value: 42)

        Principals::DeleteJob.perform_now nil

        expect(ports.last).to eq 42
      end
    end
  end
end
