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

module BasicData
  class UserCustomFieldSectionSeeder < Seeder
    def seed_data!
      # The default section is intentionally untitled — it renders the I18n fallback
      # label in the UI.  The name validation is bypassed to match the migration that
      # creates the same section for existing installations.
      section = UserCustomFieldSection.new(
        position: 1,
        attribute_order: UserCustomFieldSection::BUILT_IN_ATTRIBUTES
      )
      section.save!(validate: false)
    end

    def applicable?
      UserCustomFieldSection.none?
    end

    def not_applicable_message
      "Skipping user custom field section as there are already some configured"
    end
  end
end
