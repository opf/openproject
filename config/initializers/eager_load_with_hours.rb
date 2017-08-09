#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

# This patch is needed for eager loading spent hours for a bunch of work
# packages. The WorkPackage.include_spent_hours(user) method adds an additional
# attribute to the result set. As such 'virtual' attributes are not added to
# the model on instantiation (see: https://github.com/rails/rails/issues/15185)
# this patch has been added which is based on
# https://github.com/rails/rails/issues/15185#issuecomment-142230234

module OpenProject::Patches
  module ActiveRecordJoinPartPatch
    def instantiate(row, aliases)
      if base_klass == WorkPackage && row.has_key?('hours')
        aliases_with_hours = aliases + [['hours', 'hours']]

        super(row, aliases_with_hours)
      else
        super(row, aliases)
      end
    end
  end
end

require 'active_record'

module ActiveRecord
  module Associations
    class JoinDependency
      JoinBase && class JoinPart
                    prepend OpenProject::Patches::ActiveRecordJoinPartPatch
                  end
    end
  end
end
