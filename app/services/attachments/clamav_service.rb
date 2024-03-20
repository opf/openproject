#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Attachments
  class ClamAVService
    attr_reader :clamav_client

    def initialize(scan_mode = Setting.antivirus_scan_mode, connection_target = Setting.antivirus_scan_target)
      options = clamav_client_options(scan_mode, connection_target)
      @clamav_client = ClamAV::Client.new(**options)
    end

    def scan(attachment)
      file = attachment.diskfile
      clamav_client.execute(ClamAV::Commands::InstreamCommand.new(file))
    end

    def ping
      clamav_client.execute(ClamAV::Commands::PingCommand.new)
    end

    private

    def clamav_client_options(scan_mode, connection_target)
      case scan_mode
      when :clamav_socket
        { unix_socket: connection_target }
      when :clamav_host
        tcp_host, tcp_port = connection_target.split(':')
        { tcp_host:, tcp_port: }
      else
        raise ArgumentError.new("Unknown clamav scan mode #{scan_mode}")
      end
    end
  end
end
