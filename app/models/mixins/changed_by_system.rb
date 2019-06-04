#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Mixins
  module ChangedBySystem
    extend ActiveSupport::Concern

    def changed_by_system(attributes = nil)
      @changed_by_system ||= []

      if attributes
        @changed_by_system += Array(attributes)
      end

      @changed_by_system
    end

    def change_by_system
      prior_changes = non_no_op_changes

      ret = yield

      changed_by_system(changed_compared_to(prior_changes))

      ret
    end

    private

    def non_no_op_changes
      changes.reject { |_, (old, new)| old == 0 && new.nil? }
    end

    def changed_compared_to(prior_changes)
      changed.select { |c| !prior_changes[c] || prior_changes[c].last != changes[c].last }
    end
  end
end
