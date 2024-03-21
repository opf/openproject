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

require 'uri'
require 'cgi'

# This capsulates the validation of a requested redirect URL.
#
class RedirectPolicy
  attr_reader :validated_redirect_url, :request

  def initialize(requested_url, hostname:, default:, return_escaped: true)
    @current_host = hostname
    @return_escaped = return_escaped

    @requested_url = preprocess(requested_url)
    @default_url = default
  end

  ##
  # Performs all validations for the requested URL
  def valid?
    return false if @requested_url.nil?

    [
      # back_url must not contain two consecutive dots
      :no_upper_levels,
      # Require the path to begin with a slash
      :path_has_slash,
      # do not redirect user to another host
      :same_host,
      # do not redirect user to the login or register page
      :path_not_blacklisted,
      # do not redirect to another subdirectory
      :matches_relative_root
    ].all? { |check| send(check) }
  end

  ##
  # Return a valid redirect URI.
  # If the validation check on the current back URL apply
  def redirect_url
    if valid?
      postprocess(@requested_url)
    else
      @default_url
    end
  end

  private

  ##
  # Preprocesses the requested redirect URL.
  # - Escapes it when necessary
  # - Tries to parse it
  # - Escapes the redirect URL when requested so.
  def preprocess(requested)
    url = URI::RFC2396_Parser.new.escape(CGI.unescape(requested.to_s))
    URI.parse(url)
  rescue URI::InvalidURIError => e
    Rails.logger.warn("Encountered invalid redirect URL '#{requested}': #{e.message}")
    nil
  end

  ##
  # Postprocesses the validated URL
  def postprocess(redirect_url)
    # Remove basic auth credentials
    redirect_url.userinfo = ''

    if @return_escaped
      redirect_url.to_s
    else
      CGI.unescape(redirect_url.to_s)
    end
  end

  ##
  # Avoid paths with references to parent paths
  def no_upper_levels
    !@requested_url.path.include? '../'
  end

  ##
  # Require URLs to contain a path slash.
  # This will always be the case for parsed URLs unless
  # +URI.parse('@foo.bar')+ or a non-root relative URL  +URI.parse('foo')+
  def path_has_slash
    @requested_url.path =~ %r{\A/([^/]|\z)}
  end

  ##
  # do not redirect user to another host (even protocol relative urls have the host set)
  # whenever a host is set it must match the request's host
  def same_host
    @requested_url.host.nil? || @requested_url.host == @current_host
  end

  ##
  # Avoid redirect URLs to specific locations, such as login page
  def path_not_blacklisted
    !@requested_url.path.match(
      %r{/(
      # Ignore login since redirect to back url is result of successful login.
      login |
      # When signing out with a direct login provider enabled you will be left at the logout
      # page with a message indicating that you were logged out. Logging in from there would
      # normally cause you to be redirected to this page. As it is the logout page, however,
      # this would log you right out again after a successful login.
      logout |
      # Avoid sending users to the register form. The exact reasoning behind
      # this is unclear, but grown from tradition.
      account/register
      )}x # ignore whitespace
    )
  end

  ##
  # Requires the redirect URL to reside inside the relative root, when given.
  def matches_relative_root
    relative_root = OpenProject::Configuration['rails_relative_url_root']
    relative_root.blank? || @requested_url.path.starts_with?(relative_root)
  end
end
