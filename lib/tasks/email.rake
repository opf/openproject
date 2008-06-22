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

Available options:
  * project => identifier of the project the issue should be added to
  
Example:
  rake redmine:email:receive project=foo RAILS_ENV="production"
END_DESC

    task :receive => :environment do
      options = {}
      options[:project] = ENV['project'] if ENV['project']
      
      MailHandler.receive(STDIN.read, options)
    end
    
    desc <<-END_DESC
Read emails from an IMAP server.

Available IMAP options:
  * host      => IMAP server host (default: 127.0.0.1)
  * port      => IMAP server port (default: 143)
  * ssl       => Use SSL? (default: false)
  * username  => IMAP account
  * password  => IMAP password
  * folder    => IMAP folder to read (default: INBOX)
Other options:
  * project   => identifier of the project the issue should be added to
  
Example:
  rake redmine:email:receive_iamp host=imap.foo.bar username=redmine@somenet.foo password=xxx project=foo RAILS_ENV="production"
END_DESC

    task :receive_imap => :environment do
      imap_options = {:host => ENV['host'],
                      :port => ENV['port'],
                      :ssl => ENV['ssl'],
                      :username => ENV['username'],
                      :password => ENV['password'],
                      :folder => ENV['folder']}
                      
      options = {}
      options[:project] = ENV['project'] if ENV['project']

      Redmine::IMAP.check(imap_options, options)
    end
  end
end
