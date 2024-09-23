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

module Entry::Costs
  extend ActiveSupport::Concern

  included do
    def real_costs
      # This methods returns the actual assigned costs of the entry
      overridden_costs || costs || calculated_costs
    end

    def calculated_costs(rate_attr = nil)
      rate_attr ||= current_rate
      cost_attribute * rate_attr.rate
    rescue StandardError
      0.0
    end

    def update_costs(rate_attr = nil)
      rate_attr ||= current_rate
      if rate_attr.nil?
        self.costs = 0.0
        self.rate = nil
        return
      end

      self.costs = calculated_costs(rate_attr)
      self.rate = rate_attr
    end

    def update_costs!(rate_attr = nil)
      update_costs(rate_attr)

      save!
    end

    def cost_attribute
      raise NotImplementedError
    end
  end
end
