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

# A default user attribute section always exists in a real installation: it is
# created by a migration for existing installations and by the seeder for fresh
# installs. The administration user form and the my/account page render the
# built-in user attributes (login, mail, …) through these sections, so they only
# show up when one lists them.
#
# Seed that same default section — using the very seeder fresh installs run — for
# every spec that renders those forms, so specs match production and never rely
# on an empty table that cannot occur in practice. It is seeded per example (and
# rolled back with the example's transaction) rather than committed once, so it
# never leaks into the data-layer specs that legitimately control their own
# sections: the model, service and migration specs (the latter exercise the
# schema from before this data existed) are intentionally left untouched.
RSpec.configure do |config|
  %i[feature request view component forms].each do |spec_type|
    config.before(:each, type: spec_type) do
      BasicData::UserCustomFieldSectionSeeder.new.seed!
    end
  end
end
