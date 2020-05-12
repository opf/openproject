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

##
# Using test-prof's before_all block to safely wrap shared data in a transaction,
# shared_let acts similary to +let(:foo) { value }+ but initialized the value only once
# Changes _within_ an example will be rolled back by database cleaner,
# and the creation is rolled back in an after_all hook.
#
# Caveats: Set +reload: true+ if you plan to modify this value, otherwise Rails may still
# have cached the local value. This will perform a database update, but is much faster
# than creating new records (especially, work packages).
#
# Since test-prof added `let_it_be` this is only a wrapper for it
# before_all / let_it_be fixture
require 'test_prof/recipes/rspec/before_all'
require 'test_prof/recipes/rspec/let_it_be'

def shared_let(key, reload: true, refind: false, &block)
  let_it_be(key, reload: reload, refind: refind, &block)
end
