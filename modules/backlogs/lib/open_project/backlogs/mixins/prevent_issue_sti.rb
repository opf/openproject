#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Backlogs::Mixins
  module PreventIssueSti
    # Overrides ActiveRecord::Inheritance::ClassMethods#sti_name
    # so that stories are stored and found with type-attribute = "WorkPackage"
    def sti_name
      'WorkPackage'
    end

    # Overrides ActiveRecord::Inheritance::ClassMethods#find_sti_classes
    # so that stories are instantiated correctly despite sti_name beeing "WorkPackage"
    def find_sti_class(type_name)
      type_name = to_s if type_name == 'WorkPackage'

      super(type_name)
    end
  end
end
