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

module Webhooks
  class Log < ApplicationRecord
    belongs_to :webhook, foreign_key: :webhooks_webhook_id, class_name: "::Webhooks::Webhook", dependent: :destroy

    validates :url, presence: true
    validates :event_name, presence: true
    validates :response_code, presence: true

    serialize :response_headers, type: Hash
    serialize :request_headers, type: Hash

    validates :request_headers, presence: true, allow_blank: true
    validates :request_body, presence: true

    def self.newest(limit: 10)
      order(updated_at: :desc).limit(limit)
    end
  end
end
