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
  class Webhook < ApplicationRecord
    default_scope { order(id: :asc) }

    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validates :url, presence: true, url: true

    has_many :events, foreign_key: :webhooks_webhook_id, class_name: "::Webhooks::Event", dependent: :delete_all
    has_many :webhook_projects, foreign_key: :webhooks_webhook_id, class_name: "::Webhooks::Project", dependent: :delete_all
    has_many :projects, through: :webhook_projects
    has_many :deliveries, foreign_key: :webhooks_webhook_id, class_name: "::Webhooks::Log", dependent: :delete_all

    def self.enabled
      where(enabled: true)
    end

    def self.with_event_name(event_name)
      enabled
        .joins(:events)
        .where("#{::Webhooks::Event.table_name}.name" => event_name)
    end

    def self.new_default
      new all_projects: true, enabled: true
    end

    def all_projects?
      !!all_projects
    end

    ##
    # Check whether the webhook should fire for events
    # in the given project id
    def enabled_for_project?(project_id)
      all_projects? || projects.exists?(project_id)
    end

    def enabled?
      !!enabled
    end

    def event_names
      events.pluck(:name)
    end

    def event_names=(names)
      self.events = names.map { |name| events.build(name:) }
    end
  end
end
