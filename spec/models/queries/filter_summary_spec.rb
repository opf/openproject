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

RSpec.describe Queries::FilterSummary do
  shared_let(:job_title) do
    create(:user_custom_field, :list, name: "Job title", possible_values: %w[Developer Designer])
  end
  shared_let(:language) do
    create(:user_custom_field, :list, name: "Spoken language", multi_value: true,
                                      possible_values: %w[German English French])
  end

  def query_with(&)
    UserQuery.new.tap(&)
  end

  describe "#phrases / #to_s" do
    it "resolves a custom-field list filter's option ids to their labels" do
      option = job_title.custom_options.find_by(value: "Developer")
      query = query_with { |q| q.where(job_title.column_name, "=", [option.id.to_s]) }

      summary = described_class.new(query.filters)

      # "is (OR)" is the label OpenProject uses for the list-equals operator.
      expect(summary.phrases).to eq(["Job title is (OR) Developer"])
      expect(summary.to_s).to eq("Job title is (OR) Developer")
    end

    it "joins multiple values and multiple filters" do
      developer = job_title.custom_options.find_by(value: "Developer")
      langs = language.custom_options.where(value: %w[German English])
      query = query_with do |q|
        q.where(job_title.column_name, "=", [developer.id.to_s])
        q.where(language.column_name, "=", langs.map { |o| o.id.to_s })
      end

      summary = described_class.new(query.filters)

      expect(summary.phrases).to eq(["Job title is (OR) Developer", "Spoken language is (OR) German, English"])
      expect(summary.to_s).to eq("Job title is (OR) Developer · Spoken language is (OR) German, English")
      expect(summary.to_s(separator: "; "))
        .to eq("Job title is (OR) Developer; Spoken language is (OR) German, English")
    end

    it "is empty for no filters" do
      expect(described_class.new([])).to be_empty
      expect(described_class.new(nil).phrases).to eq([])
    end
  end

  context "with work package filters" do
    current_user { create(:admin) }

    def summary_for(name, operator, values, **)
      query = Query.new
      query.add_filter(name, operator, values)
      described_class.new(query.filters, **)
    end

    it "includes value-less operators" do
      expect(summary_for("assigned_to_id", "!*", []).to_s).to eq("Assignee is empty")
    end

    it "preserves readable values alongside missing values" do
      status = create(:status, name: "Ready")
      values = [status.id.to_s, "999999999"]
      expect(summary_for("status_id", "=", values).to_s).to eq("Status is (OR) Ready")
      expect(summary_for("status_id", "=", values, show_unavailable: true).to_s)
        .to eq("Status is (OR) Ready, Unavailable value")
    end

    it "marks missing filters" do
      expect(summary_for("cf_999999", "=", ["1"], show_unavailable: true).to_s)
        .to eq("Unavailable filter")
    end

    it "keeps the current work package symbolic" do
      expect(summary_for("parent", "=", ["{id}"], show_unavailable: true).to_s)
        .to include("current work package")
    end

    it "preserves me and an explicit current-user value" do
      expect(summary_for("assigned_to_id", "=", ["me", User.current.id.to_s], show_unavailable: true).to_s)
        .to eq("Assignee is (OR) #{I18n.t(:label_me)}, #{User.current.name}")
    end

    it "does not interpret literal text as a symbolic value" do
      expect(summary_for("subject", "~", ["me"]).to_s).to eq("Subject contains me")
    end

    {
      "<t+" => "is in less than 2 days", ">t+" => "is in more than 2 days", "t+" => "is in 2 days",
      ">t-" => "is less than 2 days ago", "<t-" => "is more than 2 days ago", "t-" => "is 2 days ago"
    }.each do |operator, phrase|
      it "spells out #{operator}" do
        expect(summary_for("start_date", operator, ["2"]).to_s).to eq("Start date #{phrase}")
      end
    end

    it "describes an open lower date range" do
      expect(summary_for("start_date", "<>d", ["2026-10-01", ""]).to_s)
        .to eq("Start date is on or after #{I18n.l(Date.new(2026, 10, 1))}")
    end

    it "describes an open upper date range" do
      expect(summary_for("start_date", "<>d", ["", "2026-10-31"]).to_s)
        .to eq("Start date is on or before #{I18n.l(Date.new(2026, 10, 31))}")
    end

    context "with personal date and time preferences" do
      current_user do
        create(:admin, preferences: { time_zone: "Europe/Berlin", date_format: "%d.%m.%Y", time_format: "%H:%M" })
      end

      it "formats datetime filters in the user's timezone and formats" do
        expect(summary_for("created_at", "=d", ["2026-09-30T22:00:00Z"]).to_s)
          .to eq("Created on on 01.10.2026 00:00")
      end

      it "accepts offsets without a colon" do
        expect(summary_for("updated_at", "=d", ["2026-10-01T09:00:00+0100"]).to_s)
          .to eq("Updated on on 01.10.2026 10:00")
      end

      it "formats date-only datetime values as dates" do
        expect(summary_for("created_at", "=d", ["2026-09-30"]).to_s)
          .to eq("Created on on 30.09.2026")
      end

      it "accepts date-only datetime ranges" do
        expect(summary_for("created_at", "<>d", ["2026-09-30", "2026-10-01"]).to_s)
          .to eq("Created on between 30.09.2026 and 01.10.2026")
      end

      it "honors date preferences for date filters" do
        expect(summary_for("start_date", "=d", ["2026-09-30"]).to_s)
          .to eq("Start date on 30.09.2026")
      end
    end

    it "labels secondary relations consistently without requiring candidate work packages" do
      expect(summary_for("follows", "!", ["{id}"], show_unavailable: true).to_s)
        .to eq("Precedes is not current work package")
    end

    it "uses the children label for a secondary parent constraint" do
      expect(summary_for("parent", "!", ["{id}"], show_unavailable: true).to_s)
        .to eq("Children is not current work package")
    end

    it "logs unexpected failures and continues with the next filter" do
      query = Query.new
      query.add_filter("subject", "~", ["broken"])
      query.add_filter("description", "~", ["readable"])
      allow(query.filters.first).to receive(:human_name).and_raise(NoMethodError, "formatter failure")
      allow(Rails.logger).to receive(:warn)
      expect(described_class.new(query.filters, show_unavailable: true).phrases)
        .to eq(["Unavailable filter", "Description contains readable"])
      expect(Rails.logger).to have_received(:warn).with(/subject.*~.*NoMethodError/)
    end

    it "does not reveal inaccessible custom-field versions" do
      field = create(:version_wp_custom_field, is_for_all: true)
      type = create(:type, custom_fields: [field])
      visible = create(:project, public: true, types: [type])
      hidden = create(:project, public: false)
      version = create(:version, project: hidden, name: "Secret version")
      allow(User).to receive(:current).and_return(create(:user))
      query = Query.new(project: visible)
      query.add_filter(field.column_name, "=", [version.id.to_s])
      expect(described_class.new(query.filters, show_unavailable: true).to_s)
        .to eq("#{field.name} is (OR) Unavailable value")
    end

    describe "visibility lookups for unavailable values" do
      def sql_for(name, values)
        query = Query.new
        query.add_filter(name, "=", values)
        filters = query.filters
        ActiveRecord::QueryRecorder.new { described_class.new(filters, show_unavailable: true).to_s }.log
      end

      it "loads only the selected projects" do
        selected = create(:project)
        create(:project)

        expect(sql_for("project_id", [selected.id.to_s]).grep(/FROM "projects"/))
          .to all(match(/"projects"\."id" (=|IN \(\$)|LIMIT/))
      end

      it "loads only the selected principals" do
        selected = create(:user)
        create(:user)

        expect(sql_for("assigned_to_id", ["me", selected.id.to_s]).grep(/FROM "users"/))
          .to all(match(/"users"\."id" (=|IN \(\$)|LIMIT/))
      end
    end

    it "does not reveal watchers to a user who may not view them" do
      project = create(:project)
      other = create(:user, member_with_permissions: { project => [:view_work_packages] })
      allow(User).to receive(:current)
        .and_return(create(:user, member_with_permissions: { project => [:view_work_packages] }))
      expect(summary_for("watcher_id", "=", [other.id.to_s], show_unavailable: true).to_s)
        .to eq("Watcher is (OR) Unavailable value")
    end

    it "marks a group as unavailable for the author filter" do
      group = create(:group)
      expect(summary_for("author_id", "=", [group.id.to_s], show_unavailable: true).to_s)
        .to eq("Author is (OR) Unavailable value")
    end

    it "marks symbolic values unavailable on filters that do not support them" do
      create(:status)
      expect(summary_for("status_id", "=", %w[me {id}], show_unavailable: true).to_s)
        .to eq("Status is (OR) Unavailable value, Unavailable value")
    end

    it "marks a deleted principal as unavailable" do
      expect(summary_for("assigned_to_id", "=", ["999999999"], show_unavailable: true).to_s)
        .to eq("Assignee is (OR) Unavailable value")
    end

    it "marks an archived project as unavailable" do
      create(:project)
      archived = create(:project, active: false)
      expect(summary_for("project_id", "=", [archived.id.to_s], show_unavailable: true).to_s)
        .to eq("Project is (OR) Unavailable value")
    end

    it "does not reveal a private project name" do
      visible = create(:project, public: true)
      hidden = create(:project, public: false, name: "Secret project")
      allow(User).to receive(:current).and_return(create(:user))
      result = summary_for("project_id", "=", [visible.id.to_s, hidden.id.to_s], show_unavailable: true).to_s
      expect(result).to include(visible.name, "Unavailable value")
      expect(result).not_to include(hidden.name)
    end

    it "continues after a missing filter" do
      query = Query.new
      query.add_filter("cf_999999", "=", ["1"])
      query.add_filter("subject", "~", ["readable"])
      expect(described_class.new(query.filters, show_unavailable: true).phrases)
        .to eq(["Unavailable filter", "Subject contains readable"])
    end

    context "with a translated phrase order" do
      include_context "with locale for testing"
      let(:translations) do
        { queries: { filter_summary: { with_values: "%<values>s / %<field>s / %<operator>s" } } }
      end

      it "uses the locale's phrase order" do
        expect(summary_for("subject", "~", ["readable"]).to_s).to eq("readable / Subject / contains")
      end
    end

    it "retains missing endpoints rather than collapsing a malformed closed range" do
      expect(summary_for("start_date", "<>d", ["bad", "2026-10-01"], show_unavailable: true).to_s)
        .to eq("Start date between Unavailable value and #{I18n.l(Date.new(2026, 10, 1))}")
      expect(summary_for("start_date", "<>d", ["", ""], show_unavailable: true).to_s)
        .to eq("Start date between Unavailable value")
    end

    it "retains readable parts of a malformed relative date" do
      expect(summary_for("start_date", "t+", ["bad"], show_unavailable: true).to_s)
        .to include("Start date", "Unavailable value")
    end
  end
end
