#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'carrierwave'

module CarrierWave
  module Configuration
    def self.configure_fog!(credentials: OpenProject::Configuration.fog_credentials,
                            directory: OpenProject::Configuration.fog_directory,
                            public: false)
      require 'fog/aws/storage'

      CarrierWave.configure do |config|
        config.fog_credentials = credentials
        config.fog_directory   = directory
        config.fog_public      = public
      end
    end
  end
end

unless OpenProject::Configuration.fog_credentials.empty?
  CarrierWave::Configuration.configure_fog!
end

CarrierWave::Storage::Fog::File.class_eval do
  ##
  # Fixed filename which was returning invalid values when using S3 as the fog storage
  # due to crappy regex magic.
  def filename(options = {})
    if file_url = url(options)
      uri = URI.parse(file_url)
      path = URI.decode uri.path
      Pathname(path).basename.to_s
    end
  end
end
