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

module Documents
  # Concern to be included in enumeration-like models within the documents module.
  module EnumerationModel
    extend ActiveSupport::Concern

    included do
      before_save :unmark_old_default_values, if: :became_default_value?
      before_save :ensure_activated, if: -> { self.class.can_have_default_value? && is_default? }
    end

    class_methods do
      def can_have_default_value?
        true
      end
    end

    def colored?
      false
    end

    def became_default_value?
      is_default? && is_default_changed?
    end

    def unmark_old_default_values
      self.class.update_all(is_default: false)
    end

    def in_use?
      Document.exists?(type_id: id)
    end

    private

    def ensure_activated
      self.active = true
    end
  end
end
