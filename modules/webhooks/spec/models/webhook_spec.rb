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

RSpec.describe Webhooks::Webhook do
  subject { build(:webhook) }

  describe "attributes" do
    describe "#url" do
      it "accepts http" do
        subject.url = "http://foo.example.org"
        expect(subject).to be_valid
      end

      it "accepts http" do
        subject.url = "https://foo.example.org"
        expect(subject).to be_valid
      end

      it "accepts other schemas" do
        subject.url = "ftp://foo.example.org"
        expect(subject).not_to be_valid
        expect(subject.errors).to have_key(:url)
      end
    end
  end

  describe "#events" do
    let(:events) { %w(work_package:updated work_package:created) }

    before do
      subject.event_names = events
      subject.save!
    end

    it "has an event association" do
      expect(subject.events.count).to eq 2
      expect(subject.event_names).to eq events
    end

    it "finds the webhook with the saved events" do
      expect(described_class.with_event_name(events[0]).first).to eq(subject)
      expect(described_class.with_event_name(events[1]).first).to eq(subject)
    end
  end

  describe "#projects" do
    let(:project1) { create(:project) }

    before do
      subject.all_projects = false
      subject.projects << project1
      subject.save!
    end

    it "has an event association" do
      expect(subject.projects.count).to eq 1
      expect(subject.project_ids).to eq([project1.id])

      expect(subject.enabled_for_project?(project1.id)).to be_truthy
      expect(subject.enabled_for_project?(project1.id + 1)).to be_falsey

      # When for all
      subject.all_projects = true
      expect(subject.enabled_for_project?(project1.id)).to be_truthy
      expect(subject.enabled_for_project?(project1.id + 1)).to be_truthy
    end
  end
end
