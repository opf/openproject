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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackagesIdentifierMode
  module_function

  def identifier(semantic:, classic:)
    Setting::WorkPackageIdentifier.semantic? ? semantic : classic
  end
end

# Runs the suite under a non-default identifier mode, e.g.
# OPENPROJECT_TESTING_WORK_PACKAGES_IDENTIFIER=classic bundle exec rspec
RSpec.configure do |config|
  config.define_derived_metadata(:classic_identifiers) do |metadata|
    metadata[:with_settings] = (metadata[:with_settings] || {}).merge(work_packages_identifier: "classic")
  end

  config.before(:suite) do
    mode = ENV["OPENPROJECT_TESTING_WORK_PACKAGES_IDENTIFIER"].presence
    next unless mode

    definition = Settings::Definition[:work_packages_identifier]
    unless definition.valid_for?(mode)
      raise ArgumentError, "OPENPROJECT_TESTING_WORK_PACKAGES_IDENTIFIER must be one of " \
                           "#{Setting::WorkPackageIdentifier::ALLOWED_VALUES.join(', ')}"
    end

    definition.value = mode
    warn "Running specs with work_packages_identifier=#{mode}"
  end
end
