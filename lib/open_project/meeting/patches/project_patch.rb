#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

module OpenProject::Meeting
  module Patches
    module ProjectPatch
      def self.included(receiver)
        receiver.class_eval do
          has_many :meetings, :include => [:author], :dependent => :destroy
        end
      end
    end
  end
end

Project.send(:include, OpenProject::Meeting::Patches::ProjectPatch)
