#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

require_dependency 'user'

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

      setting.blank? ? nil : setting
    end

    def write_backlogs_preference(attr, new_value)
      pref[:"backlogs_#{attr}"] = new_value
      pref.save! unless self.new_record?

      new_value
    end

    def compute_backlogs_preference(attr)
      case attr
      when :task_color
        ('#%0.6x' % rand(0xFFFFFF)).upcase
      when :versions_default_fold_state
        'open'
      else
        raise "Unsupported attribute '#{attr}'"
      end
    end
  end
end

User.send(:include, OpenProject::Backlogs::Patches::UserPatch)
