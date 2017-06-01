#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class AddIndexToAllTheJournals < ActiveRecord::Migration[4.2]
  def change
    # This now is only a no op.
    #
    # The creation of indexes has been moved in order to speed up migration.
    #
    # It remains here as some installations might already have
    # executed the migration.
    #
    # Moved to 20130920081135_legacy_attachment_journal_data.rb
    # add_index "attachment_journals", ["journal_id"]
    # Moved to 20130920085055_legacy_changeset_journal_data.rb
    # add_index "changeset_journals", ["journal_id"]
    # Moved to 20130920090641_legacy_message_journal_data.rb
    # add_index "message_journals", ["journal_id"]
    # Moved to 20130920090201_legacy_news_journal_data.rb
    # add_index "news_journals", ["journal_id"]
    # Moved to 20130920092800_legacy_time_entry_journal_data.rb
    # add_index "time_entry_journals", ["journal_id"]
    # Moved to 20130920093823_legacy_wiki_content_journal_data.rb
    # add_index "wiki_content_journals", ["journal_id"]
    # Moved to 20130920094524_legacy_issue_journal_data.rb
    # add_index "work_package_journals", ["journal_id"]
  end
end
