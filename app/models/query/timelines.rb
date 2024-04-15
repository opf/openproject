#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
#
module Query::Timelines
  extend ActiveSupport::Concern

  included do
    enum timeline_zoom_level: { days: 0, weeks: 1, months: 2, quarters: 3, years: 4, auto: 5 }
    validates :timeline_zoom_level, inclusion: { in: timeline_zoom_levels.keys }

    serialize :timeline_labels, type: Hash
    validate :valid_timeline_labels

    def valid_timeline_labels
      return if timeline_labels.blank?

      valid_keys = timeline_labels.keys.map(&:to_s).sort == %w(farRight left right)
      errors.add :timeline_labels, :invalid unless valid_keys
    end
  end
end
