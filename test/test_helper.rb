# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + '/helper_testcase')
require File.join(RAILS_ROOT,'test', 'mocks', 'open_id_authentication_mock.rb')

# TODO: The gem or official version of ObjectDaddy doesn't set
# protected attributes so they need to be wrapped.
def User.generate_with_protected!(attributes={})
  user = User.spawn(attributes) do |user|
    user.login = User.next_login
    attributes.each do |attr,v|
      user.send("#{attr}=", v)
    end
  end
  user.save!
  user
end

# Generate the default Query
def Query.generate_default!(attributes={})
  query = Query.spawn(attributes)
  query.name ||= '_'
  query.save!
  query
end

# Generate an issue for a project, using it's trackers
def Issue.generate_for_project!(project, attributes={})
  issue = Issue.spawn(attributes) do |issue|
    issue.project = project
  end
  issue.tracker = project.trackers.first unless project.trackers.empty?
  issue.save!
  issue
end

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  
  def log_user(login, password)
    get "/login"
    assert_equal nil, session[:user_id]
    assert_response :success
    assert_template "account/login"
    post "/login", :username => login, :password => password
    assert_equal login, User.find(session[:user_id]).login
  end
  
  def uploaded_test_file(name, mime)
    ActionController::TestUploadedFile.new(ActiveSupport::TestCase.fixture_path + "/files/#{name}", mime)
  end
  
  # Use a temporary directory for attachment related tests
  def set_tmp_attachments_directory
    Dir.mkdir "#{RAILS_ROOT}/tmp/test" unless File.directory?("#{RAILS_ROOT}/tmp/test")
    Dir.mkdir "#{RAILS_ROOT}/tmp/test/attachments" unless File.directory?("#{RAILS_ROOT}/tmp/test/attachments")
    Attachment.storage_path = "#{RAILS_ROOT}/tmp/test/attachments"
  end
  
  def with_settings(options, &block)
    saved_settings = options.keys.inject({}) {|h, k| h[k] = Setting[k].dup; h}
    options.each {|k, v| Setting[k] = v}
    yield
    saved_settings.each {|k, v| Setting[k] = v}
  end
end
