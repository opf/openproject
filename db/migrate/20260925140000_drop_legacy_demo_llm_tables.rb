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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Demo only (AI-100 PullPreview, never merged): the AI-3 stack renumbered its migrations when
# it landed on dev. Databases built from the earlier stack still hold the LLM tables under the
# old versions, so the new create_table migrations would fail. This drops those leftovers once.
class DropLegacyDemoLlmTables < ActiveRecord::Migration[8.1]
  LEGACY_VERSIONS = %w[
    20260811090000 20260811140000 20260811140100 20260812090000
    20260813090000 20260813100000 20260908090000
  ].freeze

  def up
    return unless legacy_schema?

    %i[llm_models llm_feature_bindings llm_capability_verdicts llm_connections].each do |table|
      drop_table table, if_exists: true, force: :cascade
    end

    execute "DELETE FROM schema_migrations WHERE version IN (#{LEGACY_VERSIONS.map { |v| quote(v) }.join(', ')})"
  end

  def down
    # Nothing to restore: the legacy tables belonged to a superseded version of the AI-3 stack.
  end

  private

  def legacy_schema?
    select_value("SELECT 1 FROM schema_migrations WHERE version = '20260811090000'").present?
  end
end
