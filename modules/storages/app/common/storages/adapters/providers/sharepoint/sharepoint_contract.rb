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

module Storages
  module Adapters
    module Providers
      module Sharepoint
        class SharepointContract < ::ModelContract
          attribute :name
          validates :name, presence: true, length: { maximum: 255 }

          attribute :tenant_id
          validates :tenant_id,
                    format: { with: /\A(?:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}|consumers)\z/i }
          attribute :host
          validates :host, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
          validates :host,
                    format: { with: %r{\Ahttps://[^/]+/sites/[^/]+(/.*)?\z}i,
                              message: I18n.t("activerecord.errors.messages.invalid_sharepoint_url") }
        end
      end
    end
  end
end
