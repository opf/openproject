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

require "fog/aws"
require "carrierwave"
require "carrierwave/storage/fog"

module CarrierWave
  module Configuration
    def self.configure_fog!(credentials: OpenProject::Configuration.fog_credentials,
                            directory: OpenProject::Configuration.fog_directory,
                            public: false)

      # Ensure that the provider AWS is uppercased
      provider = credentials[:provider] || "AWS"
      if [:aws, "aws"].include? provider
        credentials[:provider] = "AWS"
      end

      CarrierWave.configure do |config|
        config.fog_provider    = "fog/aws"
        config.fog_credentials = credentials
        config.fog_directory   = directory
        config.fog_public      = public

        config.use_action_status = true
      end
    end
  end
end

unless OpenProject::Configuration.fog_credentials.empty?
  CarrierWave::Configuration.configure_fog!
end
