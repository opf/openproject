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

require "rails_helper"

RSpec.describe Meetings::EmailUpdatesBannerComponent, type: :component do
  let(:project) { create(:project) }

  subject do
    render_inline(described_class.new(meeting, override: override))
    page
  end

  context "when it's a one-time meeting" do
    let(:meeting) do
      build_stubbed(:meeting,
                    project:,
                    recurring_meeting_id: nil,
                    template: false,
                    notify:)
    end
    let(:override) { nil }

    context "and notifications are enabled" do
      let(:notify) { true }

      it "renders the onetime enabled banner" do
        expect(subject).to have_text I18n.t("meeting.notifications.enabled")
        expect(subject).to have_css(".Banner")
        expect(subject).to have_no_selector(".Banner--warning")
      end
    end

    context "and notifications are disabled" do
      let(:notify) { false }

      it "renders the onetime disabled banner" do
        expect(subject).to have_text I18n.t("meeting.notifications.disabled")
        expect(subject).to have_css(".Banner--warning")
      end
    end
  end

  context "when it's a meeting series template" do
    let(:recurring_meeting) do
      create(:recurring_meeting,
             project:)
    end
    let(:meeting) do
      meeting = recurring_meeting.template
      meeting.update!(notify:)
      meeting
    end
    let(:override) { nil }

    context "and notifications are enabled" do
      let(:notify) { true }

      it "renders the template enabled banner" do
        expect(subject).to have_text I18n.t("meeting.notifications.enabled")
        expect(subject).to have_css(".Banner")
        expect(subject).to have_no_selector(".Banner--warning")
      end
    end

    context "and notifications are disabled" do
      let(:notify) { false }

      it "renders the template disabled banner" do
        expect(subject).to have_text I18n.t("meeting.notifications.disabled")
        expect(subject).to have_css(".Banner--warning")
      end
    end
  end

  context "when it's an occurrence of a meeting series" do
    let(:recurring_meeting) do
      create(:recurring_meeting,
             project:)
    end
    let(:template) do
      template = recurring_meeting.template
      template.update!(notify:)
      template
    end
    let(:meeting) do
      create(:recurring_meeting_occurrence,
             project:,
             recurring_meeting_id: recurring_meeting.id)
    end
    let(:override) { nil }

    context "and notifications are enabled" do
      let(:notify) { true }

      it "renders the occurrence enabled banner" do
        template
        expect(subject).to have_text I18n.t("meeting.notifications.enabled")
        expect(subject).to have_css(".Banner")
        expect(subject).to have_no_selector(".Banner--warning")
      end
    end

    context "and notifications are disabled" do
      let(:notify) { false }

      it "renders the occurrence disabled banner" do
        template
        expect(subject).to have_text I18n.t("meeting.notifications.disabled")
        expect(subject).to have_css(".Banner--warning")
      end
    end
  end

  context "when override is passed as 'enabled'" do
    let(:meeting) do
      build_stubbed(:meeting,
                    project:,
                    recurring_meeting_id: nil,
                    template: false,
                    notify: false)
    end
    let(:override) { "enabled" }

    it "renders the enabled banner regardless of notify" do
      expect(subject).to have_text I18n.t("meeting.notifications.enabled")
      expect(subject).to have_css(".Banner")
      expect(subject).to have_no_selector(".Banner--warning")
    end
  end

  context "when override is passed as 'disabled'" do
    let(:meeting) do
      build_stubbed(:meeting,
                    project:,
                    recurring_meeting_id: nil,
                    template: false,
                    notify: true)
    end
    let(:override) { "disabled" }

    it "renders the disabled banner regardless of notify" do
      expect(subject).to have_text I18n.t("meeting.notifications.disabled")
      expect(subject).to have_css(".Banner--warning")
    end
  end
end
