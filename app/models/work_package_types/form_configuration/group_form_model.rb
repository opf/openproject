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

module WorkPackageTypes
  module FormConfiguration
    class GroupFormModel
      include ActiveModel::Model
      include ActiveModel::Attributes
      include Tableless

      attribute :name, :string
      attribute :group_type, :string
      attribute :query, :string
      attribute :key, :string
      attribute :temporary, :boolean, default: false

      def self.model_name
        ActiveModel::Name.new(self, nil, "Group")
      end

      def self.from_group(group, name: group[:name], validation_message: nil)
        new(
          name:,
          group_type: group[:type],
          query: group[:query],
          key: group[:key],
          temporary: group[:temporary]
        ).tap do |form_model|
          form_model.errors.add(:name, validation_message) if validation_message.present?
        end
      end
    end
  end
end
