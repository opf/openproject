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

module RequiresEnterpriseGuard
  extend ActiveSupport::Concern

  included do
    class_attribute :enterprise_action
    class_attribute :enterprise_condition
    # Validate when no enterprise_condition is set, or when it evaluates to true
    validate :has_enterprise, if: -> { enterprise_condition.nil? || instance_exec(&enterprise_condition) }
  end

  module_function

  def has_enterprise
    unless EnterpriseToken.allows_to?(enterprise_action)
      errors.add :base, :error_enterprise_only, action: enterprise_action.to_s.titleize
    end
  end
end
