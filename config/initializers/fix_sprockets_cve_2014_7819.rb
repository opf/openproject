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

# Fixes an arbitrary file disclosure bug in sprockets
# see: https://groups.google.com/forum/#!topic/rubyonrails-security/wQBeGXqGs3E
# This initializer can be removes as soon as we use sprockets v2.12.X

module Sprockets
  module Server
    # `call` implements the Rack 1.x specification which accepts an
    # `env` Hash and returns a three item tuple with the status code,
    # headers, and body.
    #
    # Mapping your environment at a url prefix will serve all assets
    # in the path.
    #
    #     map "/assets" do
    #       run Sprockets::Environment.new
    #     end
    #
    # A request for `"/assets/foo/bar.js"` will search your
    # environment for `"foo/bar.js"`.
    def call(env)
      start_time = Time.now.to_f
      time_elapsed = lambda { ((Time.now.to_f - start_time) * 1000).to_i }

      msg = "Served asset #{env['PATH_INFO']} -"

      # Mark session as "skipped" so no `Set-Cookie` header is set
      env['rack.session.options'] ||= {}
      env['rack.session.options'][:defer] = true
      env['rack.session.options'][:skip] = true

      # Extract the path from everything after the leading slash
      path = unescape(env['PATH_INFO'].to_s.sub(/^\//, ''))

      # Strip fingerprint
      if fingerprint = path_fingerprint(path)
        path = path.sub("-#{fingerprint}", '')
      end

      # URLs containing a `".."` are rejected for security reasons.
      if forbidden_request?(path)
        return forbidden_response
      end

      # Look up the asset.
      asset = find_asset(path, bundle: !body_only?(env))

      # `find_asset` returns nil if the asset doesn't exist
      if asset.nil?
        logger.info "#{msg} 404 Not Found (#{time_elapsed.call}ms)"

        # Return a 404 Not Found
        not_found_response

      # Check request headers `HTTP_IF_NONE_MATCH` against the asset digest
      elsif etag_match?(asset, env)
        logger.info "#{msg} 304 Not Modified (#{time_elapsed.call}ms)"

        # Return a 304 Not Modified
        not_modified_response(asset, env)

      else
        logger.info "#{msg} 200 OK (#{time_elapsed.call}ms)"

        # Return a 200 with the asset contents
        ok_response(asset, env)
      end
    rescue Exception => e
      logger.error "Error compiling asset #{path}:"
      logger.error "#{e.class.name}: #{e.message}"

      case content_type_of(path)
      when "application/javascript"
        # Re-throw JavaScript asset exceptions to the browser
        logger.info "#{msg} 500 Internal Server Error\n\n"
        return javascript_exception_response(e)
      when "text/css"
        # Display CSS asset exceptions in the browser
        logger.info "#{msg} 500 Internal Server Error\n\n"
        return css_exception_response(e)
      else
        raise
      end
    end

    private
    def forbidden_request?(path)
      # Prevent access to files elsewhere on the file system
      #
      #     http://example.org/assets/../../../etc/passwd
      #
      path.include?("..") || Pathname.new(path).absolute?
    end

    # Gets digest fingerprint.
    #
    #     "foo-0aa2105d29558f3eb790d411d7d8fb66.js"
    #     # => "0aa2105d29558f3eb790d411d7d8fb66"
    #
    def path_fingerprint(path)
      path[/-([0-9a-f]{7,40})\.[^.]+\z/, 1]
    end
  end
end
