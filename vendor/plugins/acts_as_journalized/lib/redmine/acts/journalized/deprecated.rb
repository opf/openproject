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
      notified = project.notified_users
      notified.reject! {|user| !visible?(user)}
      notified.collect(&:mail)
    end

    def current_journal
      last_journal
    end

    # FIXME: When the new API is settled, remove me
    Redmine::Acts::Event::InstanceMethods.instance_methods(false).each do |m|
      if m.start_with? "event_"
        class_eval(<<-RUBY, __FILE__, __LINE__)
          def #{m}
            if last_journal.nil?
              begin
                journals << self.class.journal_class.create(journal_attributes)
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
            return last_journal.#{m}
          end
        RUBY
      end
    end

    def event_url(options = {})
      last_journal.event_url(options)
    end

    # deprecate :recipients => "use #last_journal.recipients"
    # deprecate :current_journal => "use #last_journal"
  end
end
