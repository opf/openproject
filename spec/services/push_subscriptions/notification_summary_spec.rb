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

RSpec.describe PushSubscriptions::NotificationSummary do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:author) { create(:user, firstname: "Ada", lastname: "Lovelace") }
  shared_let(:work_package) { create(:work_package, project:, subject: "Fix the build") }

  subject(:summary) { described_class.new(user).as_json.deep_stringify_keys }

  def notify(reason: :mentioned, resource: work_package, journal: nil, **)
    create(:notification, recipient: user, resource:, reason:, actor: author, journal:, **)
  end

  def wp_tag(work_package)
    "openproject-#{user.id}-wp-#{work_package.id}"
  end

  it "reports only the count when everything is read" do
    notify(read_ian: true)

    expect(summary).to eq("count" => 0)
  end

  it "counts several unread notifications on one work package as a single group" do
    notify(reason: :commented, created_at: 3.minutes.ago)
    notify(reason: :assigned, created_at: 2.minutes.ago)
    notify(reason: :mentioned, created_at: 1.minute.ago)

    expect(summary["count"]).to eq(3)
    expect(summary["groups"].size).to eq(1)
    expect(summary["groups"][0]).to include("count" => 3,
                                            "title" => "3 updates",
                                            "body" => "Ada Lovelace mentioned you: #{work_package.formatted_id} Fix the build")
  end

  it "scopes the tag to the recipient so another user gets a different tag for the same work package" do
    notify
    other_user = create(:user, member_with_permissions: { project => %i[view_work_packages] })
    create(:notification, recipient: other_user, resource: work_package, reason: :mentioned, actor: author)

    other_tag = described_class.new(other_user).as_json.dig(:groups, 0, :tag)

    expect(summary.dig("groups", 0, "tag")).to eq(wp_tag(work_package))
    expect(other_tag).to eq("openproject-#{other_user.id}-wp-#{work_package.id}")
  end

  it "orders groups by their latest activity" do
    older = create(:work_package, project:)
    newer = create(:work_package, project:)
    notify(resource: newer, created_at: 2.minutes.ago)
    notify(resource: older, created_at: 1.minute.ago)

    expect(summary["groups"].pluck("tag")).to eq([wp_tag(older), wp_tag(newer)])
  end

  it "puts a work package first when an aggregated journal makes its notification unread again" do
    other = create(:work_package, project:)
    journal = work_package.journals.sole
    other_journal = other.journals.sole
    journal.update_columns(updated_at: 3.minutes.ago)
    other_journal.update_columns(updated_at: 2.minutes.ago)
    aggregated = notify(read_ian: true, journal:)
    notify(resource: other, journal: other_journal)
    notify(resource: other, journal: other_journal, reason: :assigned)

    journal.update!(notes: "edited")
    Notifications::UpdateService
      .new(model: aggregated, user: author, contract_class: EmptyContract)
      .call(read_ian: false)
    expect(summary["groups"].pluck("tag")).to eq([wp_tag(work_package), wp_tag(other)])
    expect(summary["groups"].pluck("count")).to eq([1, 2])
    expect(summary["groups"].first["revision"])
      .to eq("#{aggregated.id}:#{(journal.reload.updated_at.to_f * 1000).to_i}")
  end

  it "keeps the order when a digest marks older notifications as sent" do
    older = create(:work_package, project:)
    newer = create(:work_package, project:)
    older_notification = notify(resource: older, created_at: 2.minutes.ago)
    notify(resource: newer, created_at: 1.minute.ago)

    Notification.where(id: older_notification.id).update_all(mail_reminder_sent: true, updated_at: Time.current)
    expect(summary["groups"].pluck("tag")).to eq([wp_tag(newer), wp_tag(older)])
  end

  it "caps the groups at five and reports the rest as more" do
    work_packages = create_list(:work_package, 7, project:)
    work_packages.each_with_index { |wp, i| notify(resource: wp, created_at: (7 - i).minutes.ago) }

    expect(summary["count"]).to eq(7)
    expect(summary["groups"].pluck("tag")).to eq(work_packages.last(5).reverse.map { wp_tag(it) })
    expect(summary["more"]).to eq("count" => 2, "title" => "2 more work packages", "url" => "/notifications")
  end

  context "when semantic identifiers are on", with_settings: { work_packages_identifier: "semantic" } do
    let(:semantic_project) do
      create(:project, :semantic, members: { user => create(:project_role, permissions: %i[view_work_packages]) })
    end
    let(:semantic_work_package) { create(:work_package, project: semantic_project, subject: "Fix the build") }

    it "shows and links the semantic identifier but tags the group with the numeric id" do
      notify(resource: semantic_work_package)

      expect(summary.dig("groups", 0)).to include(
        "body" => "#{semantic_work_package.formatted_id}: Fix the build",
        "url" => "/notifications/details/#{semantic_work_package.display_id}/activity",
        "tag" => wp_tag(semantic_work_package)
      )
    end
  end

  it "words date alerts without an actor" do
    create(:notification, recipient: user, resource: work_package, reason: :date_alert_due_date, actor: nil)

    expect(summary.dig("groups", 0, "title")).to eq("Due date alert")
  end

  it "has wording for every notification reason" do
    missing = Notification::REASONS.keys.reject { I18n.exists?("pwa.push.reasons.#{it}") || described_class::UPDATED_REASONS.include?(it.to_s) }

    expect(missing).to be_empty
  end

  it "falls back to the generic wording for a reason without its own text" do
    notify
    allow(I18n).to receive(:t).and_wrap_original do |original, key, **options|
      original.call(key == "pwa.push.reasons.mentioned" ? "pwa.push.reasons.unmapped" : key, **options)
    end

    expect(summary.dig("groups", 0, "title")).to eq("Ada Lovelace updated")
  end

  it "names a deleted actor" do
    notify(actor: nil)

    expect(summary.dig("groups", 0, "title")).to eq("Deleted user mentioned you")
  end

  it "uses the date alert headline when the latest of several has no actor" do
    notify(reason: :commented, created_at: 2.minutes.ago)
    create(:notification, recipient: user, resource: work_package, reason: :date_alert_due_date,
                          actor: nil, journal: nil, created_at: 1.minute.ago)

    expect(summary.dig("groups", 0, "body")).to start_with("Due date alert: ")
  end

  it "does not count mail-only notifications" do
    notify(read_ian: nil)

    expect(summary).to eq("count" => 0)
  end

  it "excludes notifications on work packages the user cannot see" do
    hidden = create(:work_package, project: create(:project))
    notify(resource: hidden)

    expect(summary).to eq("count" => 0)
  end
end
