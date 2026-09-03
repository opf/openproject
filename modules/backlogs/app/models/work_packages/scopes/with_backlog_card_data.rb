# frozen_string_literal: true

# -- copyright
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
# ++

# Loads the data a backlog work package card needs, depending on the
# +backlogs_lazy_cards+ feature flag.
#
# * On: cards are lazily loaded through turbo-frames, so only the card_hash
#   (see WorkPackages::Scopes::WithCardHash) is needed to build the frame src;
#   the associations are loaded per card by the cards controller.
# * Off: cards are rendered inline, so their associations are eager loaded to
#   avoid N+1 queries.
module WorkPackages::Scopes::WithBacklogCardData
  extend ActiveSupport::Concern

  CARD_ASSOCIATIONS = %i[type status assigned_to priority parent].freeze

  class_methods do
    def with_backlog_card_data
      if OpenProject::FeatureDecisions.backlogs_lazy_cards_active?
        with_card_hash
      else
        includes(*CARD_ASSOCIATIONS)
      end
    end
  end
end
