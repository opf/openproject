#!/usr/bin/ruby

# rdm-mailhandler
# Reads an email from standard input and forward it to a Redmine server
# Can be used from a remote mail server

require 'net/http'
require 'net/https'
require 'uri'
require 'getoptlong'

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
  
  attr_accessor :verbose, :issue_attributes, :allow_override, :url, :key

  def initialize
    self.issue_attributes = {}
    
    opts = GetoptLong.new(
      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
      [ '--version', '-V', GetoptLong::NO_ARGUMENT ],
      [ '--verbose', '-v', GetoptLong::NO_ARGUMENT ],
      [ '--url', '-u', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--key', '-k', GetoptLong::REQUIRED_ARGUMENT],
      [ '--project', '-p', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--tracker', '-t', GetoptLong::REQUIRED_ARGUMENT],
      [ '--category', GetoptLong::REQUIRED_ARGUMENT],
      [ '--priority', GetoptLong::REQUIRED_ARGUMENT],
      [ '--allow-override', '-o', GetoptLong::REQUIRED_ARGUMENT]
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
      when '--project', '--tracker', '--category', '--priority'
        self.issue_attributes[opt.gsub(%r{^\-\-}, '')] = arg.dup
      when '--allow-override'
        self.allow_override = arg.dup
      end
    end
    
    usage if url.nil?
  end
  
  def submit(email)
    uri = url.gsub(%r{/*$}, '') + '/mail_handler'
    
    data = { 'key' => key, 'email' => email, 'allow_override' => allow_override }
    issue_attributes.each { |attr, value| data["issue[#{attr}]"] = value }
             
    debug "Posting to #{uri}..."
    response = Net::HTTPS.post_form(URI.parse(uri), data)
    debug "Response received: #{response.code}"
    response.code == 201 ? 0 : 1
  end
  
  private
  
  def usage
    puts  <<-USAGE
Usage: rdm-mailhandler [options] --url=<Redmine URL> --key=<API key>
Reads an email from standard input and forward it to a Redmine server

Required:
  -u, --url                      URL of the Redmine server
  -k, --key                      Redmine API key
  
General options:
  -h, --help                     show this help
  -v, --verbose                  show extra information
  -V, --version                  show version information and exit

Issue attributes control options:
  -p, --project=PROJECT          identifier of the target project
  -t, --tracker=TRACKER          name of the target tracker
      --category=CATEGORY        name of the target category
      --priority=PRIORITY        name of the target priority
  -o, --allow-override=ATTRS     allow email content to override attributes
                                 specified by previous options
                                 ATTRS is a comma separated list of attributes
      
Examples:
  # No project specified. Emails MUST contain the 'Project' keyword:
  rdm-mailhandler --url http://redmine.domain.foo --key secret
  
  # Fixed project and default tracker specified, but emails can override
  # both tracker and priority attributes:
  rdm-mailhandler --url https://domain.foo/redmine --key secret \\
                  --project foo \\
                  --tracker bug \\
                  --allow-override tracker,priority
USAGE
    exit
  end
  
  def debug(msg)
    puts msg if verbose
  end
end

handler = RedmineMailHandler.new
handler.submit(STDIN.read)
