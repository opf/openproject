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

RSpec.describe TimeEntry do
  let(:project) { create(:project_with_types, public: false) }
  let(:project2) { create(:project_with_types, public: false) }
  let(:work_package) do
    create(:work_package, project:,
                          type: project.types.first,
                          author: user)
  end
  let(:work_package2) do
    create(:work_package, project: project2,
                          type: project2.types.first,
                          author: user2)
  end
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:date) { Time.zone.today }
  let(:rate) { build(:cost_rate) }
  let!(:hourly_one) { create(:hourly_rate, valid_from: 2.days.ago, project:, user:) }
  let!(:hourly_three) { create(:hourly_rate, valid_from: 4.days.ago, project:, user:) }
  let!(:hourly_five) { create(:hourly_rate, valid_from: 6.days.ago, project:, user:) }
  let!(:default_hourly_one) { create(:default_hourly_rate, valid_from: 2.days.ago, project:, user: user2) }
  let!(:default_hourly_three) { create(:default_hourly_rate, valid_from: 4.days.ago, project:, user: user2) }
  let!(:default_hourly_five) { create(:default_hourly_rate, valid_from: 6.days.ago, project:, user: user2) }
  let(:hours) { 5.0 }
  let(:start_time) { 10 * 60 } # 10:00
  let(:time_entry) do
    create(:time_entry,
           project:,
           entity: work_package,
           spent_on: date,
           hours:,
           start_time: start_time,
           user:,
           time_zone: user.time_zone,
           rate: hourly_one,
           comments: "lorem")
  end

  let(:time_entry2) do
    create(:time_entry,
           project:,
           entity: work_package,
           spent_on: date,
           hours:,
           user:,
           rate: hourly_one,
           comments: "lorem")
  end

  def ensure_membership(project, user, permissions)
    member = Member.find_by(principal: user, project: project)

    if member
      member.roles << create(:project_role, permissions:)
    else
      create(:member,
             project:,
             user:,
             roles: [create(:project_role, permissions:)])
    end
  end

  describe "#entity=" do
    it "allows setting an entity via GlobalID" do
      meeting = create(:meeting)
      time_entry.entity = meeting.to_gid.to_s
      expect(time_entry.entity).to eq(meeting)
    end
  end

  describe "#hours=" do
    formats = { "2" => 2.0,
                "21.1" => 21.1,
                "2,1" => 2.1,
                "1,5h" => 1.5,
                "7:12" => 7.2,
                "10h" => 10.0,
                "10 h" => 10.0,
                "45m" => 0.75,
                "45 m" => 0.75,
                "3h15" => 3.25,
                "3h 15" => 3.25,
                "3 h 15" => 3.25,
                "3 h 15m" => 3.25,
                "3 h 15 m" => 3.25,
                "3 hours" => 3.0,
                "12min" => 0.2 }

    formats.each do |from, to|
      it "formats '#{from}'" do
        t = described_class.new(hours: from)
        expect(t.hours)
          .to eql to
      end
    end
  end

  describe "#start_time=" do
    formats = {
      "720" => 720,
      "12:00" => 720,
      "13:37" => 817
    }

    formats.each do |from, to|
      it "formats '#{from}'" do
        t = described_class.new(start_time: from)
        expect(t.start_time).to eql(to)
      end
    end
  end

  it "always prefers overridden_costs" do
    allow(User).to receive(:current).and_return(user)

    value = rand(500)
    time_entry.overridden_costs = value
    expect(time_entry.overridden_costs).to eq(value)
    expect(time_entry.real_costs).to eq(value)
    time_entry.save!
  end

  describe "given rate" do
    before do
      allow(User).to receive(:current).and_return(user)
    end

    it "returns the current costs depending on the number of hours" do
      101.times do |hours|
        time_entry.hours = hours
        time_entry.save!
        expect(time_entry.costs).to eq(time_entry.rate.rate * hours)
      end
    end

    it "updates cost if a new rate is added at the end" do
      time_entry.user = User.current
      time_entry.spent_on = Time.zone.now
      time_entry.hours = 1
      time_entry.save!
      expect(time_entry.costs).to eq(hourly_one.rate)
      (hourly = HourlyRate.new.tap do |hr|
        hr.valid_from = 1.day.ago
        hr.rate       = 1.0
        hr.user       = User.current
        hr.project    = hourly_one.project
      end).save!
      time_entry.reload
      expect(time_entry.rate).not_to eq(hourly_one)
      expect(time_entry.costs).to eq(hourly.rate)
    end

    it "updates cost if a new rate is added in between" do
      time_entry.user = User.current
      time_entry.spent_on = 3.days.ago.to_date
      time_entry.hours = 1
      time_entry.save!
      expect(time_entry.costs).to eq(hourly_three.rate)
      (hourly = HourlyRate.new.tap do |hr|
        hr.valid_from = 3.days.ago.to_date
        hr.rate       = 1.0
        hr.user       = User.current
        hr.project    = hourly_one.project
      end).save!
      time_entry.reload
      expect(time_entry.rate).not_to eq(hourly_three)
      expect(time_entry.costs).to eq(hourly.rate)
    end

    it "updates cost if a spent_on changes" do
      time_entry.hours = 1
      (5.days.ago.to_date..Time.zone.today).each do |time|
        time_entry.spent_on = time.to_date
        time_entry.save!
        expect(time_entry.costs).to eq(time_entry.user.rate_at(time, project.id).rate)
      end
    end

    it "updates cost if a rate is removed" do
      time_entry.spent_on = hourly_one.valid_from
      time_entry.hours = 1
      time_entry.save!
      expect(time_entry.costs).to eq(hourly_one.rate)
      hourly_one.destroy
      time_entry.reload
      expect(time_entry.costs).to eq(hourly_three.rate)
      hourly_three.destroy
      time_entry.reload
      expect(time_entry.costs).to eq(hourly_five.rate)
    end

    it "is able to change order of rates (sorted by valid_from)" do
      time_entry.spent_on = hourly_one.valid_from
      time_entry.save!
      expect(time_entry.rate).to eq(hourly_one)
      hourly_one.valid_from = hourly_three.valid_from - 1.day
      hourly_one.save!
      time_entry.reload
      expect(time_entry.rate).to eq(hourly_three)
    end
  end

  describe "default rate" do
    let(:default_example) { time_entry2 }

    before do
      allow(User).to receive(:current).and_return(user)
    end

    it "returns the current costs depending on the number of hours" do
      101.times do |hours|
        default_example.hours = hours
        default_example.save!
        expect(default_example.costs).to eq(default_example.rate.rate * hours)
      end
    end

    it "updates cost if a new rate is added at the end" do
      default_example.user = user2
      default_example.spent_on = Time.zone.now.to_date
      default_example.hours = 1
      default_example.save!
      expect(default_example.costs).to eq(default_hourly_one.rate)
      (hourly = DefaultHourlyRate.new.tap do |dhr|
        dhr.valid_from = 1.day.ago.to_date
        dhr.rate       = 1.0
        dhr.user       = user2
      end).save!
      default_example.reload
      expect(default_example.rate).not_to eq(default_hourly_one)
      expect(default_example.costs).to eq(hourly.rate)
    end

    it "updates cost if a new rate is added in between" do
      default_example.user = user2
      default_example.spent_on = 3.days.ago.to_date
      default_example.hours = 1
      default_example.save!
      expect(default_example.costs).to eq(default_hourly_three.rate)
      (hourly = DefaultHourlyRate.new.tap do |dhr|
        dhr.valid_from = 3.days.ago.to_date
        dhr.rate       = 1.0
        dhr.user       = user2
      end).save!
      default_example.reload
      expect(default_example.rate).not_to eq(default_hourly_three)
      expect(default_example.costs).to eq(hourly.rate)
    end

    it "updates cost if a spent_on changes" do
      default_example.hours = 1
      (5.days.ago.to_date..Time.zone.today).each do |time|
        default_example.spent_on = time.to_date
        default_example.save!
        expect(default_example.costs).to eq(default_example.user.rate_at(time, project.id).rate)
      end
    end

    it "updates cost if a rate is removed" do
      default_example.spent_on = default_hourly_one.valid_from
      default_example.hours = 1
      default_example.save!
      expect(default_example.costs).to eq(default_hourly_one.rate)
      default_hourly_one.destroy
      default_example.reload
      expect(default_example.costs).to eq(default_hourly_three.rate)
      default_hourly_three.destroy
      default_example.reload
      expect(default_example.costs).to eq(default_hourly_five.rate)
    end

    it "is able to switch between default hourly rate and hourly rate" do
      default_example.user = user2
      default_example.rate = default_hourly_one
      default_example.save!
      default_example.reload
      expect(default_example.rate).to eq(default_hourly_one)

      (rate = HourlyRate.new.tap do |hr|
        hr.valid_from = 10.days.ago.to_date
        hr.rate       = 1337.0
        hr.user       = default_example.user
        hr.project    = project
      end).save!

      default_example.reload
      expect(default_example.rate).to eq(rate)
      rate.destroy
      default_example.reload
      expect(default_example.rate).to eq(default_hourly_one)
    end

    describe "#costs_visible_by?" do
      before do
        project.enabled_module_names = project.enabled_module_names << "costs"
      end

      describe "WHEN the time_entry is assigned to the user " \
               "WHEN the user has the view_own_hourly_rate permission" do
        before do
          ensure_membership(project, user, [:view_own_hourly_rate])

          time_entry.user = user
        end

        it { expect(time_entry).to be_costs_visible_by(user) }
      end

      describe "WHEN the time_entry is assigned to the user " \
               "WHEN the user lacks permissions" do
        before do
          ensure_membership(project, user, [])

          time_entry.user = user
        end

        it { expect(time_entry).not_to be_costs_visible_by(user) }
      end

      describe "WHEN the time_entry is assigned to another user " \
               "WHEN the user has the view_hourly_rates permission" do
        before do
          ensure_membership(project, user2, [:view_hourly_rates])

          time_entry.user = user
        end

        it { expect(time_entry).to be_costs_visible_by(user2) }
      end

      describe "WHEN the time_entry is assigned to another user " \
               "WHEN the user has the view_hourly_rates permission in another project" do
        before do
          ensure_membership(project2, user2, [:view_hourly_rates])

          time_entry.user = user
        end

        it { expect(time_entry).not_to be_costs_visible_by(user2) }
      end
    end
  end

  describe "visible_by?" do
    context "when not having the necessary permissions" do
      before do
        ensure_membership(project, user, [])
      end

      it "is visible" do
        expect(time_entry).not_to be_visible_by(user)
      end
    end

    context "when having the view_time_entries permission" do
      before do
        ensure_membership(project, user, [:view_time_entries])
      end

      it "is visible" do
        expect(time_entry).to be_visible_by(user)
      end
    end

    context "when having the view_own_time_entries permission " \
            "and being the owner of the time entry" do
      before do
        ensure_membership(project, user, [:view_own_time_entries])

        time_entry.user = user
      end

      it "is visible" do
        expect(time_entry).to be_visible_by(user)
      end
    end

    context "when having the view_own_time_entries permission " \
            "and not being the owner of the time entry" do
      before do
        ensure_membership(project, user, [:view_own_time_entries])

        time_entry.user = build :user
      end

      it "is visible" do
        expect(time_entry).not_to be_visible_by(user)
      end
    end
  end

  describe ".can_track_start_and_end_time?" do
    context "with the setting enabled", with_settings: { allow_tracking_start_and_end_times: true } do
      it { expect(described_class).to be_can_track_start_and_end_time }
    end

    context "with the setting disabled", with_settings: { allow_tracking_start_and_end_times: false } do
      it { expect(described_class).not_to be_can_track_start_and_end_time }
    end
  end

  describe "validations" do
    it "allows the correct entity types" do
      expect(described_class::ALLOWED_ENTITY_TYPES).to contain_exactly("WorkPackage", "Meeting")
    end

    it { is_expected.to validate_inclusion_of(:entity_type).in_array(described_class::ALLOWED_ENTITY_TYPES).allow_blank }

    describe "start_time" do
      it "allows blank values" do
        time_entry.start_time = nil
        expect(time_entry).to be_valid
      end

      it "allows integer values between 0 and 1440" do
        time_entry.start_time = (5 * 60) + 30
        expect(time_entry).to be_valid
      end

      it "allows string time values" do
        time_entry.start_time = "12:00"
        expect(time_entry).to be_valid
      end

      it "does not allow times > 23:59" do
        time_entry.start_time = "26:00"
        expect(time_entry).not_to be_valid
        expect(time_entry.errors.full_messages).to include("Start time must be between 00:00 and 23:59.")
      end

      it "does not allow non integer values" do
        time_entry.start_time = 1.5
        expect(time_entry).not_to be_valid
      end

      it "does not allow negative values" do
        time_entry.start_time = -42
        expect(time_entry).not_to be_valid
      end

      context "when enforcing times" do
        before do
          allow(described_class).to receive(:must_track_start_and_end_time?).and_return(true)
        end

        it "validates that both values are present" do
          time_entry.start_time = nil

          expect(time_entry).not_to be_valid

          time_entry.start_time = 10 * 60

          expect(time_entry).to be_valid
        end
      end
    end

    describe "comments" do
      it "allows blank values" do
        time_entry.comments = ""
        expect(time_entry).to be_valid
      end

      it "allows values with a length of 1000 characters" do
        time_entry.comments = "a" * 1000
        expect(time_entry).to be_valid
      end

      it "does not allow values with a length of >1000 characters" do
        time_entry.comments = "a" * 1001
        expect(time_entry).not_to be_valid
      end
    end
  end

  describe "#start_timestamp" do
    it "returns nil if start_time is nil" do
      time_entry.start_time = nil
      expect(time_entry.start_timestamp).to be_nil
    end

    it "returns nil if timezone is nil" do
      time_entry.time_zone = nil
      expect(time_entry.start_timestamp).to be_nil
    end

    it "generates a proper timestamp from the stored information" do
      time_entry.start_time = 14 * 60
      time_entry.spent_on = Date.new(2024, 12, 24)
      time_entry.time_zone = "America/Los_Angeles"

      expect(time_entry.start_timestamp.iso8601).to eq("2024-12-24T14:00:00-08:00")
    end
  end

  describe "#end_timestamp" do
    it "returns nil if start_time is nil" do
      time_entry.start_time = nil
      expect(time_entry.end_timestamp).to be_nil
    end

    it "returns nil if timezone is nil" do
      time_entry.time_zone = nil
      expect(time_entry.end_timestamp).to be_nil
    end

    it "returns nil if hours are nil" do
      time_entry.hours = nil
      expect(time_entry.end_timestamp).to be_nil
    end

    it "generates a proper timestamp from the stored information" do
      time_entry.start_time = 8 * 60
      time_entry.hours = 2.5
      time_entry.spent_on = Date.new(2024, 12, 24)
      time_entry.time_zone = "America/Los_Angeles"

      expect(time_entry.end_timestamp.iso8601).to eq("2024-12-24T10:30:00-08:00")
    end
  end

  describe ".must_track_start_and_end_time?" do
    context "when the EnterpriseToken does not allow enforcement", with_ee: [] do
      context "with the allow setting enabled", with_settings: { allow_tracking_start_and_end_times: true } do
        context "with the enforce setting enabled", with_settings: { enforce_tracking_start_and_end_times: true } do
          it { expect(described_class).not_to be_must_track_start_and_end_time }
        end

        context "with the enforce setting disabled", with_settings: { enforce_tracking_start_and_end_times: false } do
          it { expect(described_class).not_to be_must_track_start_and_end_time }
        end
      end

      context "with the allow setting disabled", with_settings: { allow_tracking_start_and_end_times: false } do
        context "with the enforce setting enabled", with_settings: { enforce_tracking_start_and_end_times: true } do
          it { expect(described_class).not_to be_must_track_start_and_end_time }
        end

        context "with the enforce setting disabled", with_settings: { enforce_tracking_start_and_end_times: false } do
          it { expect(described_class).not_to be_must_track_start_and_end_time }
        end
      end
    end

    context "when the EnterpriseToken allows enforcement", with_ee: [:time_entry_time_restrictions] do
      context "with the allow setting enabled", with_settings: { allow_tracking_start_and_end_times: true } do
        context "with the enforce setting enabled", with_settings: { enforce_tracking_start_and_end_times: true } do
          it { expect(described_class).to be_must_track_start_and_end_time }
        end

        context "with the enforce setting disabled", with_settings: { enforce_tracking_start_and_end_times: false } do
          it { expect(described_class).not_to be_must_track_start_and_end_time }
        end
      end

      context "with the allow setting disabled", with_settings: { allow_tracking_start_and_end_times: false } do
        context "with the enforce setting enabled", with_settings: { enforce_tracking_start_and_end_times: true } do
          it { expect(described_class).not_to be_must_track_start_and_end_time }
        end

        context "with the enforce setting disabled", with_settings: { enforce_tracking_start_and_end_times: false } do
          it { expect(described_class).not_to be_must_track_start_and_end_time }
        end
      end
    end
  end

  describe "deprecated work package association" do
    it "ignores the deprecated work package association" do
      expect(described_class.ignored_columns).to include("work_package_id")
    end

    it "allows access to the work package" do
      allow(OpenProject::Deprecation).to receive(:replaced)

      time_entry.entity = work_package
      expect(time_entry.work_package).to eq(work_package)

      time_entry.entity = create(:meeting)
      expect(time_entry.work_package).to be_nil

      expect(OpenProject::Deprecation).to have_received(:replaced).twice.with(:work_package, :entity, any_args)
    end

    it "allows access to the work package ID" do
      allow(OpenProject::Deprecation).to receive(:replaced)

      time_entry.entity = work_package
      expect(time_entry.work_package_id).to eq(work_package.id)

      time_entry.entity = create(:meeting)
      expect(time_entry.work_package_id).to be_nil

      expect(OpenProject::Deprecation).to have_received(:replaced).twice.with(:work_package_id, :entity_id, any_args)
    end

    it "allows setting the work package" do
      allow(OpenProject::Deprecation).to receive(:replaced)

      time_entry.work_package = work_package
      expect(time_entry.entity).to eq(work_package)

      expect(OpenProject::Deprecation).to have_received(:replaced).with(:work_package=, :entity=, any_args)
    end

    it "allows setting the work package ID" do
      allow(OpenProject::Deprecation).to receive(:replaced)

      time_entry.entity_type = nil # to make sure that we properly set it
      time_entry.work_package_id = work_package.id
      expect(time_entry.entity).to eq(work_package)
      expect(time_entry.entity_type).to eq("WorkPackage")
      expect(time_entry.entity_id).to eq(work_package.id)

      expect(OpenProject::Deprecation).to have_received(:replaced).with(:work_package_id=, :entity_id=, any_args)
    end
  end

  it_behaves_like "acts_as_customizable included", admin_only_allowed: false, comments: false do
    let!(:model_instance) { time_entry }
    let!(:new_model_instance) do
      build(:time_entry,
            project:,
            entity: work_package,
            spent_on: date,
            hours:,
            start_time: start_time,
            user:,
            time_zone: user.time_zone,
            rate: hourly_one,
            comments: "lorem")
    end
    let!(:custom_field) { create(:time_entry_custom_field, :string, is_required: false) }

    context "with a required custom field" do
      let!(:custom_field) { create(:time_entry_custom_field, :string, is_required: true) }

      before do
        new_model_instance.activate_custom_field_validations!
      end

      context "for a new not-ongoing entry" do
        let!(:new_model_instance) do
          build(:time_entry, entity: work_package, spent_on: date, hours:, user:, ongoing: false)
        end

        it "validates presence of the custom field" do
          new_model_instance.custom_field_values = { custom_field.id => nil }
          expect(new_model_instance).not_to be_valid

          new_model_instance.custom_field_values = { custom_field.id => "Some value" }
          expect(new_model_instance).to be_valid
        end
      end

      context "for a new ongoing entry" do
        let!(:new_model_instance) do
          build(:time_entry, entity: work_package, spent_on: date, hours:, user:, ongoing: true)
        end

        it "does not validate presence of the custom field" do
          new_model_instance.custom_field_values = { custom_field.id => nil }
          expect(new_model_instance).to be_valid
        end
      end

      context "for a persisted not-ongoing entry" do
        let!(:new_model_instance) do
          create(:time_entry, entity: work_package, spent_on: date, hours:, user:, ongoing: false)
        end

        it "validates presence of the custom field" do
          new_model_instance.custom_field_values = { custom_field.id => nil }

          expect(new_model_instance).not_to be_valid

          new_model_instance.custom_field_values = { custom_field.id => "Some value" }
          expect(new_model_instance).to be_valid
        end
      end

      context "for a persisted ongoing entry" do
        let!(:new_model_instance) do
          create(:time_entry, entity: work_package, spent_on: date, hours:, user:, ongoing: true)
        end

        it "validates presence of the custom field" do
          new_model_instance.custom_field_values = { custom_field.id => nil }
          expect(new_model_instance).not_to be_valid
        end
      end
    end
  end
end
