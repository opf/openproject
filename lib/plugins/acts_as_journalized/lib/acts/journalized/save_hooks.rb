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
module Acts::Journalized
  module SaveHooks
    def self.included(base)
      base.class_eval do
        after_save :save_journals

        attr_accessor :journal_notes, :journal_user
      end
    end

    def save_journals
      with_ensured_journal_attributes do
        create_call = Journals::CreateService
                      .new(self, @journal_user)
                      .call(notes: @journal_notes)

        if create_call.success? && create_call.result
          OpenProject::Notifications.send('journal_created',
                                          journal: create_call.result,
                                          send_notification: Journal::NotificationConfiguration.active?)
        end

        create_call.success?
      end
    end

    def add_journal(user = User.current, notes = '')
      self.journal_user ||= user
      self.journal_notes ||= notes
    end

    private

    def with_ensured_journal_attributes
      self.journal_user ||= User.current
      self.journal_notes ||= ''

      yield
    ensure
      self.journal_user = nil
      self.journal_notes = nil
    end
  end
end
