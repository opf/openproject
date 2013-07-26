#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
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
