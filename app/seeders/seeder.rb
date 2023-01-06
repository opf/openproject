#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class Seeder
  def seed!
    if applicable?
      without_notifications do
        seed_data!
      end
    else
      Rails.logger.debug { "   *** #{not_applicable_message}" }
    end
  end

  def seed_data!
    raise NotImplementedError
  end

  def applicable?
    true
  end

  def not_applicable_message
    "Skipping #{self.class.name}"
  end

  protected

  def print_status(message)
    Rails.logger.info message

    yield if block_given?
  end

  ##
  # Translate the given string with the fixed interpolation for base_url
  # Deep interpolation is required in order for interpolations on hashes to work!
  def translate_with_base_url(string, **i18n_options)
    I18n.t(string, deep_interpolation: true, base_url: "{{opSetting:base_url}}", **i18n_options)
  end

  def edition_data_for(key)
    translate_with_base_url("seeders.#{OpenProject::Configuration['edition']}.#{key}", default: nil)
  end

  def demo_data_for(key)
    edition_data_for("demo_data.#{key}")
  end

  def project_data_for(project, key)
    demo_data_for "projects.#{project}.#{key}"
  end

  def project_has_data_for?(project, key)
    I18n.exists?("seeders.#{OpenProject::Configuration['edition']}.demo_data.projects.#{project}.#{key}")
  end

  def without_notifications(&)
    Journal::NotificationConfiguration.with(false, &)
  end
end
