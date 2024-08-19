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

##
# Using test-prof's before_all block to safely wrap shared data in a transaction,
# shared_let acts similarly to +let(:foo) { value }+ but initialized the value only once
# Changes _within_ an example will be rolled back by database cleaner,
# and the creation is rolled back in an after_all hook.
#
# Caveats: Set +reload: true+ if you plan to modify this value, otherwise Rails may still
# have cached the local value. This will perform a database select, but is much faster
# than creating new records (especially, work packages).
#
# Since test-prof added `let_it_be` this is only a wrapper for it
# before_all / let_it_be fixture
def shared_let(key, reload: true, refind: false, &)
  let_it_be(key, reload:, refind:, &)
end

# Defines an object to be used by default for all FactoryBot association
# matching they key name.
#
# The object is created only once in the example group, and reused for each
# example. Under the hood, it uses +let_it_be+ and +FactoryDefault+ from the
# test_prof gem.
#
# For instance, when creating work packages with +create(:work_package)+, a new
# user gets created for each create work package. To reuse the same user for all
# created work packages, in your example group add:
#
#   shared_association_default(:user) { create(:user) }
#
def shared_association_default(key, factory_name: key, &)
  # unique let identifier to prevent clashes
  let_it_be(key, reload: true, &)

  before_all do
    set_factory_default(factory_name, send(key))
  end
end

# Use this to boost performance in tests creating lots of work packages.
def create_shared_association_defaults_for_work_package_factory
  shared_association_default(:priority) { create(:priority) }
  shared_association_default(:project_with_types) { create(:project_with_types) }
  shared_association_default(:status) { create(:status) }
  shared_association_default(:user) { create(:user) }
end
