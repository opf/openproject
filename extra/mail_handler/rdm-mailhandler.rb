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

# !/usr/bin/env ruby

# == Synopsis
#
# Reads an email from standard input and forward it to a Redmine server
# through a HTTP request.
#
# == Usage
#
#    rdm-mailhandler [options] --url=<Redmine URL> --key=<API key>
#
# == Arguments
#
#   -u, --url                      URL of the Redmine server
#   -k, --key                      Redmine API key
#
# General options:
#       --unknown-user=ACTION      how to handle emails from an unknown user
#                                  ACTION can be one of the following values:
#                                  ignore: email is ignored (default)
#                                  accept: accept as anonymous user
#                                  create: create a user account
#       --no-permission-check      disable permission checking when receiving
#                                  the email
#   -h, --help                     show this help
#   -v, --verbose                  show extra information
#   -V, --version                  show version information and exit
#
# Issue attributes control options:
#   -p, --project=PROJECT          identifier of the target project
#   -s, --status=STATUS            name of the target status
#   -t, --type=TYPE                name of the target type
#       --category=CATEGORY        name of the target category
#       --priority=PRIORITY        name of the target priority
#   -o, --allow-override=ATTRS     allow email content to override attributes
#                                  specified by previous options
#                                  ATTRS is a comma separated list of attributes
#
# == Examples
# No project specified. Emails MUST contain the 'Project' keyword:
#
#   rdm-mailhandler --url http://redmine.domain.foo --key secret
#
# Fixed project and default type specified, but emails can override
# both type and priority attributes using keywords:
#
#   rdm-mailhandler --url https://domain.foo/redmine --key secret \\
#                   --project foo \\
#                   --type bug \\
#                   --allow-override type,priority

require "net/http"
require "net/https"
require "uri"
require "getoptlong"
require "rdoc/usage"

module Net
  class HTTPS < HTTP
    def self.post_form(url, params, headers)
      request = Post.new(url.path)
      request.form_data = params
      request.basic_auth url.user, url.password if url.user
      request.initialize_http_header(headers)
      http = new(url.host, url.port)
      http.use_ssl = (url.scheme == "https")
      http.start { |h| h.request(request) }
    end
  end
end

class RedmineMailHandler
  VERSION = "0.1"

  attr_accessor :verbose, :issue_attributes, :allow_override, :unknown_user, :no_permission_check, :url, :key

  def initialize
    self.issue_attributes = {}

    opts = GetoptLong.new(
      ["--help",           "-h", GetoptLong::NO_ARGUMENT],
      ["--version",        "-V", GetoptLong::NO_ARGUMENT],
      ["--verbose",        "-v", GetoptLong::NO_ARGUMENT],
      ["--url",            "-u", GetoptLong::REQUIRED_ARGUMENT],
      ["--key",            "-k", GetoptLong::REQUIRED_ARGUMENT],
      ["--project",        "-p", GetoptLong::REQUIRED_ARGUMENT],
      ["--status",         "-s", GetoptLong::REQUIRED_ARGUMENT],
      ["--type",           "-t", GetoptLong::REQUIRED_ARGUMENT],
      ["--category",             GetoptLong::REQUIRED_ARGUMENT],
      ["--priority",             GetoptLong::REQUIRED_ARGUMENT],
      ["--allow-override", "-o", GetoptLong::REQUIRED_ARGUMENT],
      ["--unknown-user",         GetoptLong::REQUIRED_ARGUMENT],
      ["--no-permission-check",  GetoptLong::NO_ARGUMENT]
    )

    opts.each do |opt, arg|
      case opt
      when "--url"
        self.url = arg.dup
      when "--key"
        self.key = arg.dup
      when "--help"
        usage
      when "--verbose"
        self.verbose = true
      when "--version"
        puts VERSION
        exit
      when "--project", "--status", "--type", "--category", "--priority"
        issue_attributes[opt.gsub(%r{^--}, "")] = arg.dup
      when "--allow-override"
        self.allow_override = arg.dup
      when "--unknown-user"
        self.unknown_user = arg.dup
      when "--no-permission-check"
        self.no_permission_check = "1"
      end
    end

    RDoc.usage if url.nil?
  end

  def submit(email)
    uri = url.gsub(%r{/*\z}, "") + "/mail_handler"

    headers = { "User-Agent" => "Redmine mail handler/#{VERSION}" }

    data = { "key" => key, "email" => email,
             "allow_override" => allow_override,
             "unknown_user" => unknown_user,
             "no_permission_check" => no_permission_check }
    issue_attributes.each { |attr, value| data["issue[#{attr}]"] = value }

    debug "Posting to #{uri}..."
    response = Net::HTTPS.post_form(URI.parse(uri), data, headers)
    debug "Response received: #{response.code}"

    case response.code.to_i
    when 403
      warn "Request was denied by your Redmine server. " +
           "Make sure that 'WS for incoming emails' is enabled in application settings and that you provided the correct API key."
      77
    when 422
      warn "Request was denied by your Redmine server. " +
           "Possible reasons: email is sent from an invalid email address or is missing some information."
      77
    when 400..499
      warn "Request was denied by your Redmine server (#{response.code})."
      77
    when 500..599
      warn "Failed to contact your Redmine server (#{response.code})."
      75
    when 201
      debug "Processed successfully"
      0
    else
      1
    end
  end

  private

  def debug(msg)
    puts msg if verbose
  end
end

handler = RedmineMailHandler.new
exit(handler.submit(STDIN.read))
