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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "services/base_services/behaves_like_create_service"

RSpec.describe Reminders::CreateService do
  it_behaves_like "BaseServices create service" do
    let(:factory) { :reminder }

    before do
      allow(model_instance).to receive(:update_columns).and_return(true)
      allow(Reminders::ScheduleReminderJob).to receive(:schedule)
        .with(model_instance)
        .and_return(instance_double(Reminders::ScheduleReminderJob, job_id: 1))
    end

    it "schedules a reminder job" do
      subject

      expect(Reminders::ScheduleReminderJob).to have_received(:schedule).with(model_instance)
      expect(model_instance).to have_received(:update_columns).with(job_id: 1)
    end
  end
end
