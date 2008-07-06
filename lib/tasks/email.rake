# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

namespace :redmine do
  namespace :email do

    desc <<-END_DESC
Read an email from standard input.

Issue attributes control options:
  project=PROJECT          identifier of the target project
  tracker=TRACKER          name of the target tracker
  category=CATEGORY        name of the target category
  priority=PRIORITY        name of the target priority
  allow_override=ATTRS     allow email content to override attributes
                           specified by previous options
                           ATTRS is a comma separated list of attributes

Examples:
  # No project specified. Emails MUST contain the 'Project' keyword:
  rake redmine:email:read RAILS_ENV="production" < raw_email

  # Fixed project and default tracker specified, but emails can override
  # both tracker and priority attributes:
  rake redmine:email:read RAILS_ENV="production" \\
                  project=foo \\
                  tracker=bug \\
                  allow_override=tracker,priority < raw_email
END_DESC

    task :read => :environment do
      options = { :issue => {} }
      %w(project tracker category priority).each { |a| options[:issue][a.to_sym] = ENV[a] if ENV[a] }
      options[:allow_override] = ENV['allow_override'] if ENV['allow_override']
      
      MailHandler.receive(STDIN.read, options)
    end
    
    desc <<-END_DESC
Read emails from an IMAP server.

Available IMAP options:
  host=HOST                IMAP server host (default: 127.0.0.1)
  port=PORT                IMAP server port (default: 143)
  ssl=SSL                  Use SSL? (default: false)
  username=USERNAME        IMAP account
  password=PASSWORD        IMAP password
  folder=FOLDER            IMAP folder to read (default: INBOX)

Issue attributes control options:
  project=PROJECT          identifier of the target project
  tracker=TRACKER          name of the target tracker
  category=CATEGORY        name of the target category
  priority=PRIORITY        name of the target priority
  allow_override=ATTRS     allow email content to override attributes
                           specified by previous options
                           ATTRS is a comma separated list of attributes
  
Examples:
  # No project specified. Emails MUST contain the 'Project' keyword:
  
  rake redmine:email:receive_iamp RAILS_ENV="production" \\
    host=imap.foo.bar username=redmine@somenet.foo password=xxx


  # Fixed project and default tracker specified, but emails can override
  # both tracker and priority attributes:
  
  rake redmine:email:receive_iamp RAILS_ENV="production" \\
    host=imap.foo.bar username=redmine@somenet.foo password=xxx ssl=1 \\
    project=foo \\
    tracker=bug \\
    allow_override=tracker,priority
END_DESC

    task :receive_imap => :environment do
      imap_options = {:host => ENV['host'],
                      :port => ENV['port'],
                      :ssl => ENV['ssl'],
                      :username => ENV['username'],
                      :password => ENV['password'],
                      :folder => ENV['folder']}
                      
      options = { :issue => {} }
      %w(project tracker category priority).each { |a| options[:issue][a.to_sym] = ENV[a] if ENV[a] }
      options[:allow_override] = ENV['allow_override'] if ENV['allow_override']

      Redmine::IMAP.check(imap_options, options)
    end
  end
end
