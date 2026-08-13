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

require "spec_helper"

RSpec.describe OpenProject::EnvironmentVariablesDocumentation do
  it "has a documentation page that is up to date" do
    expect(File.read(described_class.path)).to eq(described_class.to_markdown), <<~ERR
      #{described_class::PAGE_PATH} no longer matches the settings defined in the code.

      Probably a setting was added, removed, renamed, or its default or description
      changed. To fix it, regenerate the page by running

          bundle exec rake docs:env_vars

      and commit the change.

      If you just did that and this still fails, the default of the setting shown in
      the diff differs between Rails environments, or it is read from the database.
      Such a default cannot be documented; add the setting to
      #{described_class}::ENVIRONMENT_DEPENDENT_DEFAULTS and regenerate again.
    ERR
  end

  it "does not document a default that is computed on every read" do
    computed = Settings::Definition.all.values.filter_map do |definition|
      definition.name.to_sym if definition.instance_variable_get(:@default).respond_to?(:call)
    end

    documented = computed - described_class.masked_setting_names - described_class::EVALUATED_PROC_DEFAULTS

    expect(documented).to be_empty, <<~ERR
      The default of #{documented.to_sentence} is a proc, so it is evaluated every time
      the documentation is generated. That risks writing a random value, a value read
      from the database, or a value that only holds in the environment the task happened
      to run in, into #{described_class::PAGE_PATH}.

      Add the setting to one of these, in #{described_class}:

      * RANDOM_DEFAULTS, if the proc generates a new value on every call
      * ENVIRONMENT_DEPENDENT_DEFAULTS, if the value depends on the Rails environment,
        the process environment or the database
      * EVALUATED_PROC_DEFAULTS, if the proc returns the same value everywhere and does
        not touch the database

      then run `bundle exec rake docs:env_vars`.
    ERR
  end
end
