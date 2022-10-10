#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
module LegacyAssertionsAndHelpers
  extend ActiveSupport::Concern

  ##
  # Resets any global state that may have been changed through tests and the change of which
  # should not affect other tests.
  def reset_global_state!
    User.current = User.anonymous # reset current user in case it was changed in a test
    ActionMailer::Base.deliveries.clear
    RequestStore.clear!
  end

  def with_legacy_settings(options, &)
    saved_settings = options.keys.inject({}) do |h, k|
      h[k] = Setting[k].dup
      h
    end
    options.each { |k, v| Setting[k] = v }
    yield
  ensure
    saved_settings.each { |k, v| Setting[k] = v }
  end

  # Shoulda macros
  def should_assign_to(variable, &block)
    # it "assign the instance variable '#{variable}'" do
    assert @controller.instance_variables.map(&:to_s).include?("@#{variable}")
    if block
      expected_result = instance_eval(&block)
      assert_equal @controller.instance_variable_get('@' + variable.to_s), expected_result
    end
    # end
  end

  def should_render_404
    should respond_with :not_found
    should render_template 'common/error'
  end

  def should_respond_with_content_type(content_type)
    # it "respond with content type '#{content_type}'" do
    assert_equal response.content_type, content_type
    # end
  end

  def assert_error_tag(options = {})
    assert_select('body', { attributes: { id: 'errorExplanation' } }.merge(options))
  end

  def credentials(login, password = nil)
    if password.nil?
      password = (login == 'admin' ? 'adminADMIN!' : login)
    end
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(login, password) }
  end

  def repository_configured?(vendor)
    self.class.repository_configured?(vendor)
  end

  module ClassMethods
    def ldap_configured?
      return false if !!ENV['CI']

      @test_ldap = Net::LDAP.new(host: '127.0.0.1', port: 389)
      @test_ldap.bind
    rescue Exception => e
      # LDAP is not listening
      nil
    end

    # Returns the path to the test +vendor+ repository
    def repository_path(vendor)
      File.join(Rails.root.to_s.gsub(%r{config/\.\.}, ''), "/tmp/test/#{vendor.downcase}_repository")
    end

    # Returns the url of the subversion test repository
    def subversion_repository_url
      path = repository_path('subversion')
      path = '/' + path unless path.starts_with?('/')
      "file://#{path}"
    end

    # Returns true if the +vendor+ test repository is configured
    def repository_configured?(vendor)
      File.directory?(repository_path(vendor))
    end
  end
end
