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

module Wikis
  class Provider < ApplicationRecord
    self.table_name = "wiki_providers"

    has_many :page_links, dependent: :destroy
    has_many :health_reports, as: :subject, dependent: :delete_all

    scope :enabled, -> { where(enabled: true) }
    scope :visible, ->(_user = User.current) { all }

    validates :name, presence: true, uniqueness: true, length: { maximum: 255 }

    before_create :generate_universal_identifier

    def configured? = raise SubclassResponsibilityError

    def non_confidential_configuration
      {
        enabled:
      }
    end

    def to_s = self.class.registry_prefix
    def user_connected?(_user) = raise SubclassResponsibilityError

    def auth_strategy_for(user)
      resolve("authentication.user_bound").call(user)
    end

    class << self
      def registry_prefix = raise SubclassResponsibilityError
    end

    def resolve(registry_path, **init_options)
      Adapters::Registry["#{self.class.registry_prefix}.#{registry_path}"].new(model: self, **init_options)
    end

    def inspect
      "#<#{self.class.name} id: #{id} name: #{name}>"
    end

    private

    def generate_universal_identifier
      self.universal_identifier ||= SecureRandom.uuid
    end
  end
end
