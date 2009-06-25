#!/usr/bin/env ruby

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
#   -h, --help                     show this help
#   -v, --verbose                  show extra information
#   -V, --version                  show version information and exit
# 
# Issue attributes control options:
#   -p, --project=PROJECT          identifier of the target project
#   -s, --status=STATUS            name of the target status
#   -t, --tracker=TRACKER          name of the target tracker
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
# Fixed project and default tracker specified, but emails can override
# both tracker and priority attributes using keywords:
# 
#   rdm-mailhandler --url https://domain.foo/redmine --key secret \\
#                   --project foo \\
#                   --tracker bug \\
#                   --allow-override tracker,priority

require 'net/http'
require 'net/https'
require 'uri'
require 'getoptlong'
require 'rdoc/usage'

module Net
  class HTTPS < HTTP
    def self.post_form(url, params)
      request = Post.new(url.path)
      request.form_data = params
      request.basic_auth url.user, url.password if url.user
      http = new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.start {|h| h.request(request) }
    end
  end
end

class RedmineMailHandler
  VERSION = '0.1'
  
  attr_accessor :verbose, :issue_attributes, :allow_override, :unknown_user, :url, :key

  def initialize
    self.issue_attributes = {}
    
    opts = GetoptLong.new(
      [ '--help',           '-h', GetoptLong::NO_ARGUMENT ],
      [ '--version',        '-V', GetoptLong::NO_ARGUMENT ],
      [ '--verbose',        '-v', GetoptLong::NO_ARGUMENT ],
      [ '--url',            '-u', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--key',            '-k', GetoptLong::REQUIRED_ARGUMENT],
      [ '--project',        '-p', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--status',         '-s', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--tracker',        '-t', GetoptLong::REQUIRED_ARGUMENT],
      [ '--category',             GetoptLong::REQUIRED_ARGUMENT],
      [ '--priority',             GetoptLong::REQUIRED_ARGUMENT],
      [ '--allow-override', '-o', GetoptLong::REQUIRED_ARGUMENT],
      [ '--unknown-user',         GetoptLong::REQUIRED_ARGUMENT]
    )

    opts.each do |opt, arg|
      case opt
      when '--url'
        self.url = arg.dup
      when '--key'
        self.key = arg.dup
      when '--help'
        usage
      when '--verbose'
        self.verbose = true
      when '--version'
        puts VERSION; exit
      when '--project', '--status', '--tracker', '--category', '--priority'
        self.issue_attributes[opt.gsub(%r{^\-\-}, '')] = arg.dup
      when '--allow-override'
        self.allow_override = arg.dup
      when '--unknown-user'
        self.unknown_user = arg.dup
      end
    end
    
    RDoc.usage if url.nil?
  end
  
  def submit(email)
    uri = url.gsub(%r{/*$}, '') + '/mail_handler'
    
    data = { 'key' => key, 'email' => email, 
                           'allow_override' => allow_override,
                           'unknown_user' => unknown_user }
    issue_attributes.each { |attr, value| data["issue[#{attr}]"] = value }
             
    debug "Posting to #{uri}..."
    response = Net::HTTPS.post_form(URI.parse(uri), data)
    debug "Response received: #{response.code}"
    
    puts "Request was denied by your Redmine server. " + 
         "Please, make sure that 'WS for incoming emails' is enabled in application settings and that you provided the correct API key." if response.code == '403'
    response.code == '201' ? 0 : 1
  end
  
  private
  
  def debug(msg)
    puts msg if verbose
  end
end

handler = RedmineMailHandler.new
handler.submit(STDIN.read)
