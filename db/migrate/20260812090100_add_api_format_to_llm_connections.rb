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

# Named with a capital API: config/initializers/inflections.rb registers "API"
# as an acronym, so Rails resolves this file to AddAPIFormatToLlmConnections and
# silently skips a class spelled any other way.
class AddAPIFormatToLlmConnections < ActiveRecord::Migration[8.1]
  def change
    # Which dialect the server speaks. Only "openai" is implemented; the column
    # exists so that adding Azure -- the one non-OpenAI format with a real
    # constituency under #62215's bring-your-own-infrastructure goal -- is a new
    # adapter rather than a migration.
    change_table :llm_connections, bulk: true do |t|
      t.string :api_format, null: false, default: "openai"
      # Provider-specific headers sent with every request, e.g. Azure's
      # api-version or a gateway's own key header.
      t.jsonb :custom_headers, null: false, default: {}
    end
  end
end
