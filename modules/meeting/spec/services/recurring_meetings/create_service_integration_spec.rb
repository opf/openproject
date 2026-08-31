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

RSpec.describe RecurringMeetings::CreateService, "integration", type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i(view_meetings create_meetings) })
  end
  let(:business_day_at_noon) { Time.zone.parse("2025-01-08T12:00:00Z") }
  let(:instance) { described_class.new(user:) }
  let(:service_result) { subject }
  let(:series) { service_result.result }
  let(:params) { {} }

  subject { instance.call(**params) }

  before do
    travel_to(business_day_at_noon)
  end

  after do
    travel_back
  end

  shared_examples "creates the series" do
    it "creates the series and template" do
      expect(service_result).to be_success
      expect(series).to be_persisted

      expect(series.template).to be_a(Meeting)
      expect(series.template).to be_template

      expect(series.meetings.count).to eq(1)
      expect(series.meetings.first).to be_template
    end
  end

  describe "project" do
    context "when not provided" do
      let(:params) { { title: "foo" } }

      it "complains about the project, not the base authorization" do
        expect(subject).not_to be_success
        expect(subject.errors[:base]).to be_empty
        expect(subject.errors[:project_id]).to contain_exactly "can't be blank."
      end
    end
  end

  context "with a daily schedule" do
    let(:first_start) { Time.zone.tomorrow + 10.hours }
    let(:params) do
      {
        start_time: first_start,
        frequency: "daily",
        interval: 1,
        end_after: "specific_date",
        end_date: 1.month.from_now,
        project:,
        title: "My daily"
      }
    end

    it_behaves_like "creates the series"

    context "when the template cannot be saved" do
      let(:template) { Meeting.new }

      before do
        allow(Meeting).to receive(:new).and_return(template)
        allow(template).to receive(:save).and_return(false)
      end

      it "does not create the series" do
        expect { subject }.not_to have_enqueued_job(RecurringMeetings::InitNextOccurrenceJob)
        expect(service_result).not_to be_success
        expect(series).to be_new_record
      end
    end
  end

  describe "start time constraints" do
    let(:params) do
      {
        start_time:,
        frequency: "daily",
        interval: 1,
        end_after: "never",
        project:,
        title: "My daily"
      }
    end

    context "when start_time is today, but in the past" do
      let(:start_time) { 1.hour.ago }

      it "adds a validation error for start_time_hour" do
        expect(service_result).not_to be_success
        expect(service_result.errors[:start_time_hour]).to include "must be in the future."
        expect(series).to be_new_record
      end
    end

    context "when start_time is today, but in the future" do
      let(:start_time) { 1.hour.from_now }

      it_behaves_like "creates the series"
    end

    context "when start_time is tomorrow" do
      let(:start_time) { 1.day.from_now }

      it_behaves_like "creates the series"
    end

    context "when start_time is yesterday" do
      let(:start_time) { 1.day.ago }

      it "adds a validation error for start_date" do
        expect(service_result).not_to be_success
        expect(service_result.errors[:start_date]).to include "must be in the future."
        expect(series).to be_new_record
      end
    end
  end
end
