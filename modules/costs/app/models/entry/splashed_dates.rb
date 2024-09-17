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

module Entry::SplashedDates
  extend ActiveSupport::Concern

  included do
    # tyear, tmonth, tweek assigned where setting spent_on attributes
    # these attributes make time aggregations easier
    def spent_on=(date)
      super
      if spent_on.is_a?(Time)
        self.spent_on = spent_on.to_date
      end
      set_tyear
      set_tmonth
      set_tweek
    end

    private

    def set_tyear
      self.tyear = spent_on ? spent_on.year : nil
    end

    def set_tmonth
      self.tmonth = spent_on ? spent_on.month : nil
    end

    def set_tweek
      self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
    end
  end
end
