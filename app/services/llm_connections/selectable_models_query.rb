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

module LlmConnections
  # The models offerable to a feature.
  #
  # A feature is offered the models of its own kind: chat features never see an
  # embedding model, and an embedding feature sees only models known to embed.
  # Offering a model on the grounds that nothing has ruled it out invites a
  # choice whose failure surfaces much later, at index time.
  #
  # The one exception is the model a feature is already bound to. It stays
  # listed even once it no longer qualifies, flagged, so that opening the page
  # cannot silently blank a working binding.
  class SelectableModelsQuery
    Option = Data.define(:model_id, :qualifies)

    def initialize(connection, feature)
      @connection = connection
      @feature = feature
    end

    def call
      offerable_model_ids.map { |model_id| Option.new(model_id:, qualifies: qualifying_ids.include?(model_id)) }
    end

    private

    attr_reader :connection, :feature

    def offerable_model_ids
      (qualifying_ids + [bound_model_id]).compact_blank.uniq
    end

    # Models an administrator has switched off are not offered: both lists are
    # built from the selectable ones.
    def qualifying_ids
      @qualifying_ids ||= feature.embedding? ? connection.embedding_model_ids : connection.chat_model_ids
    end

    def bound_model_id
      connection.feature_bindings.find_by(feature_key: feature.key.to_s)&.model_id
    end
  end
end
