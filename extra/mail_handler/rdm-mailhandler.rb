#!/usr/bin/ruby

# rdm-mailhandler
# Reads an email from standard input and forward it to a Redmine server
# Can be used from a remote mail server

require 'net/http'
require 'net/https'
require 'uri'
require 'getoptlong'

class RedmineMailHandler
  VERSION = '0.1'
  
  attr_accessor :verbose, :project, :url, :key

  def initialize
    opts = GetoptLong.new(
      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
      [ '--version', '-V', GetoptLong::NO_ARGUMENT ],
      [ '--verbose', '-v', GetoptLong::NO_ARGUMENT ],
      [ '--url', '-u', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--key', '-k', GetoptLong::REQUIRED_ARGUMENT],
      [ '--project', '-p', GetoptLong::REQUIRED_ARGUMENT ]
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
      when '--project'
        self.project = arg.dup
      end
    end
    
    usage if url.nil?
  end
  
  def submit(email)
    uri = url.gsub(%r{/*$}, '') + '/mail_handler'
    debug "Posting to #{uri}..."
    data = { 'key' => key, 'project' => project, 'email' => email }
    response = Net::HTTP.post_form(URI.parse(uri), data)
    debug "Response received: #{response.code}"
    response.code == 201 ? 0 : 1
  end
  
  private
  
  def usage
    puts "Usage: rdm-mailhandler [options] --url=<Redmine URL> --key=<API key>"
    puts "Reads an email from standard input and forward it to a Redmine server"
    puts
    puts "Options:"
    puts "  --help             show this help"
    puts "  --verbose          show extra information"
    puts "  --project          identifier of the target project"
    puts
    puts "Examples:"
    puts "  rdm-mailhandler --url http://redmine.domain.foo --key secret"
    puts "  rdm-mailhandler --url https://redmine.domain.foo --key secret --project foo"
    exit
  end
  
  def debug(msg)
    puts msg if verbose
  end
end

handler = RedmineMailHandler.new
handler.submit(STDIN.read)
