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

require "socket"

module OpenProject
  module Dev
    # Development-only stand-in for the reverse proxy: tunnels the AnyCable WebSocket and SSE
    # endpoints to a local anycable-go so they are same-origin with the app and receive the
    # session cookie (EventSource does not send credentials cross-origin).
    class CableTunnel
      PATHS = %w[/cable /events].freeze

      def initialize(app, target: URI(ENV.fetch("ANYCABLE_DEV_URL", "http://localhost:8080")))
        @app = app
        @target = target
      end

      def call(env)
        return @app.call(env) unless PATHS.include?(env["PATH_INFO"]) && env["rack.hijack?"]

        upstream = TCPSocket.new(@target.host, @target.port)
        upstream.write(request_head(env))
        pipe(env["rack.hijack"].call, upstream)

        [-1, {}, []]
      rescue SystemCallError => e
        [502, { "content-type" => "text/plain" }, ["anycable-go is not reachable at #{@target}: #{e.message}"]]
      end

      private

      def request_head(env)
        query = env["QUERY_STRING"].presence
        request_line = "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}#{"?#{query}" if query} HTTP/1.1"
        headers = env.filter_map do |key, value|
          "#{key.delete_prefix('HTTP_').tr('_', '-')}: #{value}" if key.start_with?("HTTP_")
        end

        [request_line, *headers, "", ""].join("\r\n")
      end

      def pipe(client, upstream)
        [[client, upstream], [upstream, client]].each do |from, to|
          Thread.new do
            IO.copy_stream(from, to)
          rescue IOError, SystemCallError
            nil
          ensure
            [from, to].each { |io| io.close unless io.closed? }
          end
        end
      end
    end
  end
end
