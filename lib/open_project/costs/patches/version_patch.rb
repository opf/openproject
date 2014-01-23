#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module OpenProject::Costs::Patches::VersionPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :spent_hours, :inheritance
    end
  end

  module InstanceMethods
    def spent_hours_with_inheritance
      # overwritten method
      @spent_hours ||= TimeEntry.visible.sum(:hours, :include => :work_package, :conditions => ["#{WorkPackage.table_name}.fixed_version_id = ?", id]).to_f
    end
  end
end
