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

module OpenProject
  # Live updates are pushed through AnyCable once it is configured; until then features keep polling.
  module LiveUpdates
    class NotEnabledError < StandardError; end

    module_function

    def enabled?
      AnyCable::Rails.enabled? &&
        AnyCable.config.secret.present? &&
        AnyCable.config.websocket_url.present?
    end

    # The event dispatched on `document` in pages subscribed to a record of the model via `turbo_stream_from`,
    # e.g. "op-dispatched:meeting-changed".
    def changed_event(model)
      "#{OpTurbo::ComponentStream::DISPATCHED_EVENT_PREFIX}#{model.model_name.element.dasherize}-changed"
    end

    # Signals the pages subscribed to the record that it changed.
    # The Turbo request id lets the tab that made the change recognize and ignore the signal.
    # Callers may run inside the transaction persisting the change, so the signal waits for its commit.
    # Callers check #enabled? first, as pages fall back to polling without live updates.
    def broadcast_changed(record)
      raise NotEnabledError, "Live updates are not configured" unless enabled?

      detail = { requestId: Turbo.current_request_id }.compact.to_json

      ActiveRecord.after_all_transactions_commit do
        Turbo::StreamsChannel.broadcast_action_to(
          record,
          action: :dispatchEvent,
          attributes: { "event-name": changed_event(record), detail: }
        )
      end
    end
  end
end
