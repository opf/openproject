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

# Refinement to also remove SQL comments when using +String#squish+.
#
# To use it, add +using CoreExtensions::SquishSql+. Refinements are scoped.
# See https://docs.ruby-lang.org/en/3.1/syntax/refinements_rdoc.html
module CoreExtensions::SquishSql
  refine String do
    # Like +squish+ from ActiveSupport, and also removes single line sql
    # comments.
    #
    #   <<~SQL.squish
    #     -- select existing users from given IDs
    #     SELECT id AS user_id
    #     FROM users
    #     WHERE id IN (:user_ids)
    #   SQL
    #   => "SELECT id as user_id FROM users WHERE id IN (:user_ids)"
    def squish
      dup.squish!
    end

    # Performs a destructive squish. See String#squish.
    def squish!
      gsub!(/[[:space:]]*--[^\r\n]*$/, " ")
      super
    end
  end
end
