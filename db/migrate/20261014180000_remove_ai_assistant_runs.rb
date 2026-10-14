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

# Every skill answers in a conversation, and the built-in rules are gone: runs, their
# findings, "Not checked" and the checks setting are no longer used. The data is dropped,
# because the feature was never released.
class RemoveAIAssistantRuns < ActiveRecord::Migration[8.1]
  def up
    drop_table :ai_assistant_run_findings
    drop_table :ai_assistant_runs
    remove_column :ai_assistant_chat_messages, :not_checked
    execute "UPDATE ai_assistant_skills SET settings = settings - 'checks'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
