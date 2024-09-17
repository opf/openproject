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

module OpenProject::Backlogs::Patches::UserPatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods
    end
  end

  module InstanceMethods
    def backlogs_preference(attr, new_value = nil)
      setting = read_backlogs_preference(attr)

      if setting.nil? and new_value.nil?
        new_value = compute_backlogs_preference(attr)
      end

      if new_value.present?
        setting = write_backlogs_preference(attr, new_value)
      end

      setting
    end

    protected

    def read_backlogs_preference(attr)
      setting = pref[:"backlogs_#{attr}"]

      setting.presence
    end

    def write_backlogs_preference(attr, new_value)
      pref[:"backlogs_#{attr}"] = new_value
      pref.save! unless new_record?

      new_value
    end

    def compute_backlogs_preference(attr)
      case attr
      when :task_color
        ("#%0.6x" % rand(0xFFFFFF)).upcase
      when :versions_default_fold_state
        "open"
      else
        raise "Unsupported attribute '#{attr}'"
      end
    end
  end
end

User.include OpenProject::Backlogs::Patches::UserPatch
