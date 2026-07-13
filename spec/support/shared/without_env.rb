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

# Helper to remove a variable from ENV and reset its setting.
# Usage:
# it "runs a spec", without_env: ["OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET"] do
RSpec.configure do |config|
  config.include_context "with settings reset"

  config.around do |example|
    environment_overrides = aggregate_metadata(example, :without_env)
    keys_to_reset = environment_overrides.to_set
    previous = ENV.to_hash

    if environment_overrides.present?
      environment_overrides.each do |override|
        ENV.delete(override) # e.g. OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET
        cleaned_override = override.gsub("__", "_")
        keys_to_reset << cleaned_override
        ENV.delete(cleaned_override) # e.g. OPENPROJECT_COLLABORATIVE_EDITING_HOCUSPOCUS_SECRET
        reset(cleaned_override.delete_prefix("OPENPROJECT_").downcase.to_sym) # e.g. :collaborative_editing_hocuspocus_secret
        example.run
      end
    else
      example.run
    end
  ensure
    keys_to_reset&.each do |key|
      if previous&.key?(key)
        ENV[key] = previous[key]
      end
    end
  end
end
