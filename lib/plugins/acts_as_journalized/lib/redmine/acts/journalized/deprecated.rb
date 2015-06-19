#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

#-- encoding: UTF-8
# This file is part of the acts_as_journalized plugin for the redMine
# project management software
#
# Copyright (C) 2010  Finn GmbH, http://finn.de
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

# These hooks make sure journals are properly created and updated with Redmine user detail,
# notes and associated custom fields

module Redmine::Acts::Journalized
  module Deprecated
    # Old mailer API
    def recipients
      notified = []
      notified = project.notified_users if project
      notified.reject! { |user| !visible?(user) }
      notified.map(&:mail)
    end

    def current_journal
      last_journal
    end

    # FIXME: When the new API is settled, remove me
    Redmine::Acts::Event::InstanceMethods.instance_methods(false).each do |m|
      if m.to_s.start_with? 'event_'
        class_eval(<<-RUBY, __FILE__, __LINE__)
          def #{m}
            if last_journal.nil?
              begin
                JournalManager.add_journal self
                save!
                reset_journal_changes
                reset_journal
                true
              rescue Exception => e # FIXME: What to do? This likely means that the parent record is invalid!
                p e
                p e.message
                p e.backtrace
                false
              end
              journals.reload
            end
            return last_journal.data.#{m}
          end
        RUBY
      end
    end

    def event_url(options = {})
      last_journal.data.event_url(options)
    end

    # deprecate :recipients => "use #last_journal.recipients"
    # deprecate :current_journal => "use #last_journal"
  end
end
