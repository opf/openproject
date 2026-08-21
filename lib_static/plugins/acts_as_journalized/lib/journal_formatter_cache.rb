# frozen_string_literal: true

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

class JournalFormatterCache
  def self.request_instance
    RequestStore.store[:journal_formatter_cache] ||= new
  end

  def self.fetch(...) = request_instance.fetch(...)

  def initialize
    @cache = Hash.new
  end

  # The reader is folded into the key by default, so a verdict or a scoped id set
  # cached while serving one user can never be read back for another — see
  # JournalFormatter::NamedAssociation#reachable? for the same rationale. This is
  # a no-op for the raw-record lookups NamedAssociation/PolymorphicAssociation
  # cache here (User.current is constant for the life of a request), so it's
  # free to apply unconditionally rather than leaving it as an easy-to-forget
  # opt-in for permission-sensitive callers.
  def fetch(klass, id, user: User.current, &)
    key = [klass, id, user.id]
    if @cache.key?(key)
      @cache[key]
    elsif block_given?
      @cache[key] = yield
    end
  end
end
