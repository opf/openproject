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

# The text actions seeded before 18.0 were placeholders behind a feature flag. The seeder only seeds an
# empty table, so once the placeholders are gone, the db:seed that follows every migration installs the
# released defaults. Actions an administrator created themselves are kept.
class DeletePreReleaseAITextActions < ActiveRecord::Migration[8.1]
  PRE_RELEASE_LABELS = ["Fix grammar", "Make concise", "Translate to English", "Sort into template"].freeze

  def up
    execute <<~SQL.squish
      DELETE FROM ai_text_actions
      WHERE label IN (#{PRE_RELEASE_LABELS.map { |label| connection.quote(label) }.join(', ')})
    SQL
  end

  def down
    # The deleted actions cannot be restored.
  end
end
