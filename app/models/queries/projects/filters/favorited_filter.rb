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

class Queries::Projects::Filters::FavoritedFilter < Queries::Projects::Filters::Base
  include Queries::Filters::Shared::BooleanFilter

  def self.key
    # The filter used to be called favored.
    # To support:
    # * Stored queries
    # * API clients
    # having that filter, the old key is also supported.
    /favorited|favored/
  end

  def self.all_for(context = nil)
    # Override superclass method to support the old name of the filter (see above).
    [
      create!(name: :favorited, context:),
      create!(name: :favored, context:)
    ]
  end

  def human_name
    I18n.t(:label_favorite)
  end

  def available?
    User.current.logged?
  end

  def apply_to(_query_scope)
    if filtering_for_true?
      super.where(id: favorited_project_ids)
    else
      super.where.not(id: favorited_project_ids)
    end
  end

  # Handled by scope
  def where
    nil
  end

  def favorited_project_ids
    Favorite
      .where(favorited_type: "Project", user_id: User.current.id)
      .select(:favorited_id)
  end
end
