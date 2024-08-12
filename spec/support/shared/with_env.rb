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

# Aggregates example and parent metadata for a given key.
def aggregate_metadata(example, metadata_key)
  hash = example.metadata[metadata_key] || {}
  example.example_group.module_parents.each do |parent|
    if parent.respond_to?(:metadata) && parent.metadata[metadata_key]
      hash.reverse_merge!(parent.metadata[metadata_key])
    end
  end
  hash
end

module WithEnvMixin
  module_function

  def with_env(environment_overrides, &)
    ClimateControl.modify(environment_overrides, &)
  end
end

RSpec.configure do |config|
  config.include WithEnvMixin

  config.around do |example|
    environment_overrides = aggregate_metadata(example, :with_env)
    if environment_overrides.present?
      with_env(environment_overrides) do
        example.run
      end
    else
      example.run
    end
  end
end
