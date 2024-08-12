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

FactoryBot.define do
  factory :journal do
    user factory: :user
    created_at { Time.zone.now }
    updated_at { created_at }
    validity_period { created_at..Float::INFINITY }
    sequence(:version, 1)

    callback(:before_create) do |journal|
      # If there is a predecessor to the newly created journal, update the validity period of the predecessor
      # to end at the creation time of the new journal.
      Journal
        .where(journable_id: journal.journable_id,
               journable_type: journal.journable_type,
               version: journal.version - 1)
        .where("upper(validity_period) IS NULL")
        .update_all(["validity_period = tstzrange(journals.created_at, ?)", journal.created_at])
    end

    factory :work_package_journal, class: "Journal" do
      journable_type { "WorkPackage" }
      data { build(:journal_work_package_journal) }

      callback(:after_stub) do |journal, options|
        journal.journable ||= options.journable || build_stubbed(:work_package)
      end
    end

    factory :wiki_page_journal, class: "Journal" do
      journable_type { "WikiPage" }
      data { build(:journal_wiki_page_journal) }

      callback(:after_stub) do |journal, options|
        journal.journable ||= options.journable || build_stubbed(:wiki_page)
      end
    end

    factory :message_journal, class: "Journal" do
      journable_type { "Message" }
      data { build(:journal_message_journal) }
    end

    factory :news_journal, class: "Journal" do
      journable_type { "News" }
      data { build(:journal_message_journal) }
    end

    factory :project_journal, class: "Journal" do
      journable factory: :project
      data { build(:journal_project_journal) }
    end

    factory :time_entry_journal, class: "Journal" do
      journable_type { "TimeEntry" }
      data { association(:journal_time_entry_journal) }
    end
  end
end
