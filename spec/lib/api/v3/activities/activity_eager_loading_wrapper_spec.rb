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

RSpec.describe API::V3::Activities::ActivityEagerLoadingWrapper, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:, author: user) }
  shared_let(:meeting) { create(:meeting, project:, author: user) }

  describe ".wrap" do
    it "returns wrapped journals with relations eager loaded" do
      9.times { |i| work_package.update(subject: "Subject ##{i}") }

      journals = Journal.for_work_package
      wrapped_journals = described_class.wrap(journals)

      expect(wrapped_journals.size).to eq(journals.size)
      wrapped_journals.each do |loaded_journal|
        expect(loaded_journal.__getobj__.instance_variables).to include(:@predecessor)
        %i[journable data].each do |association|
          expect(loaded_journal.association_cached?(association)).to be true
        end
      end
    end

    it "can wrap Project journals" do
      expect(project.journals).to be_wrappable
    end

    it "can wrap Document journals" do
      document = create(:document, project:)
      expect(document.journals).to be_wrappable
    end

    it "can wrap TimeEntry journals" do
      time_entry = create(:time_entry, project:, work_package:, user:)
      expect(time_entry.journals).to be_wrappable
    end

    it "can wrap Meeting journals" do
      expect(meeting.journals).to be_wrappable
    end

    it "can wrap MeetingAgenda journals" do
      meeting_agenda = create(:meeting_agenda, meeting:)
      expect(meeting_agenda.journals).to be_wrappable
    end

    it "can wrap MeetingMinutes journals" do
      meeting_minutes = create(:meeting_minutes, meeting:)
      expect(meeting_minutes.journals).to be_wrappable
    end

    it "can wrap Budget journals" do
      budget = create(:budget, project:, author: user)
      expect(budget.journals).to be_wrappable
    end

    it "can wrap WorkPackage journals" do
      expect(work_package.journals).to be_wrappable
    end

    it "can wrap Changeset journals" do
      changeset = create(:changeset, repository: create(:repository_git, project:))
      expect(changeset.journals).to be_wrappable
    end

    it "can wrap News journals" do
      news = create(:news, project:, author: user)
      expect(news.journals).to be_wrappable
    end

    it "can wrap WikiPage journals" do
      wiki_content = create(:wiki_page, author: user)
      expect(wiki_content.journals).to be_wrappable
    end

    it "can wrap Message journals" do
      message = create(:message, author: user)
      expect(message.journals).to be_wrappable
    end
  end
end

RSpec::Matchers.define :be_wrappable do
  match do |journals|
    wrapped_journals = described_class.wrap(journals)
    wrapped_journals.size == journals.size
  end

  failure_message do |journals|
    "expected that wrapped size of journals would match the size of journals (#{journals.size})"
  end
end
