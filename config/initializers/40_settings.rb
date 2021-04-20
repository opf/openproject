#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# Needs to run before the first access of a setting.

require Rails.root.join('config/constants/settings/available')

Settings::Available.add :smtp_enable_starttls_auto,
                        format: :boolean,
                        api_name: 'smtpEnableStartTLSAuto',
                        default: false,
                        admin: true

Settings::Available.add :smtp_ssl,
                        format: :boolean,
                        api_name: 'smtpSSL',
                        default: false,
                        admin: true

Settings::Available.add :smtp_address,
                        format: :string,
                        default: '',
                        admin: true

Settings::Available.add :smtp_port,
                        format: :int,
                        default: 587,
                        admin: true

YAML::load(File.open(Rails.root.join('config/settings.yml'))).map do |name, config|
  Settings::Available.add name,
                          format: config['format'],
                          default: config['default'],
                          serialized: config.fetch('serialized', false),
                          api: false
end
