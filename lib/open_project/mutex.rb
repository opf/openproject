#-- encoding: UTF-8

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

module OpenProject
  module Mutex
    module_function

    # Adds a mutex on database level via advisory locks:
    # https://www.postgresql.org/docs/12/explicit-locking.html
    # employing the with_advisory_lock gem.
    # This leads to requests received in parallel by two different workers, which might be in different OS processes
    # on different hosts, to be executed sequentially.
    # The locks are, from an abstract perspective, on row level as the entry's id is taken to create the lock.
    # Other entries of the same class can still be created/updated.
    # Relying on explicit row level locking (e.g. ROW EXCLUSIVE FOR UPDATE) would not work, I believe, as it would still
    # allow reading. Allowing reading is desirable in some cases, e.g. when fetching for the work package list, but would not
    # prevent the creation of journals. The journals transaction could not be committed, but the faulty view of the entries
    # current state could be committed anyway afterwards. See below for details.
    #
    # We in particular have to wait until the transaction is complete.
    # Otherwise the following is e.g. possible:
    # Action 1 writes an attachment and releases the lock.
    # Action 2, running in parallel, writes an attachment and releases the lock.
    # Action 3 updates something, some time later.
    # Both have not yet committed their transaction so, given that we have the "READ COMMITTED" transaction level,
    # the two actions cannot yet see the attachment added by the respective other action.
    # Both actions now proceed to write their journals, which will create attachable journals based on the attachments
    # at that time. But given that both do not see the attachment added by the other action yet, they only add
    # attachable journals for the attachment added by themselves. To the user this will look as if one of the actions
    # deleted the other attachment. The next action, Action 3,  will then seem to have readded the attachment,
    # seemingly removed before.
    def with_advisory_lock_transaction(entry, &block)
      ActiveRecord::Base.transaction do
        with_advisory_lock(entry, &block)
      end
    end

    def with_advisory_lock(entry)
      lock_name = "mutex_on_#{entry.class.name}_#{entry.id}"

      debug_log("Attempting to fetched advisory lock", lock_name)
      result = entry.class.with_advisory_lock(lock_name, transaction: true) do
        debug_log("Fetched advisory lock", lock_name)
        yield
      end
      debug_log("Released advisory lock", lock_name)

      result
    end

    def debug_log(action, lock_name)
      message = <<~MESSAGE
        #{action}:
          * lockname: #{lock_name}
          * thread:  #{Thread.current.object_id}
          * held locks: #{WithAdvisoryLock::Base.lock_stack.map(&:name).join(', ')}
      MESSAGE

      Rails.logger.debug { message }
    end
  end
end
