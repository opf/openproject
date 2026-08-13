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

namespace :docs do
  desc "Regenerate the documented list of supported environment variables (production only)"
  task env_vars: :environment do
    documentation = OpenProject::EnvironmentVariablesDocumentation

    # Writing the page from another environment would document the wrong defaults.
    unless Rails.env.production?
      abort <<~ABORT
        Refusing to write #{documentation::DOC_PATH} from the #{Rails.env} environment:
        the defaults of a good number of settings differ per environment, and the page
        documents production installations. Run

            RAILS_ENV=production bundle exec rake docs:env_vars
      ABORT
    end

    # Refuse rather than write values the spec cannot catch, as it skips defaults.
    configured = documentation.configured_derived_inputs
    if configured.any?
      abort <<~ABORT
        Refusing to write #{documentation::DOC_PATH}: this instance has
        #{configured.keys.to_sentence} configured, and the defaults of
        default_projects_modules and real_time_text_collaboration_enabled are derived from
        them. Generate on an installation that has none of them set, or neutralise them
        for the run:

            RAILS_ENV=production SECRET_KEY_BASE=unused_for_docs_generation \\
              #{configured.values.join(" \\\n      ")} \\
              bundle exec rake docs:env_vars
      ABORT
    end

    File.write(documentation.path, documentation.update(File.read(documentation.path)))

    puts "Updated the generated list in #{documentation::DOC_PATH}"
  end
end
