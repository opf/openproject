# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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

require "#{File.dirname(__FILE__)}/../../test_helper"
require 'pp'
class ApiTest::NewsTest < ActionController::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
  end

  context "GET /news" do
    context ".xml" do
      should "return news" do
        get '/news.xml'
        
        assert_tag :tag => 'news',
          :attributes => {:type => 'array'},
          :child => {
            :tag => 'news',
            :child => {
              :tag => 'id',
              :content => '2'
            }
          }
      end
    end
    
    context ".json" do
      should "return news" do
        get '/news.json'
        
        json = ActiveSupport::JSON.decode(response.body)
        assert_kind_of Hash, json
        assert_kind_of Array, json['news']
        assert_kind_of Hash, json['news'].first
        assert_equal 2, json['news'].first['id']
      end
    end
  end

  context "GET /projects/:project_id/news" do
    context ".xml" do
      should_allow_api_authentication(:get, "/projects/onlinestore/news.xml")
      
      should "return news" do
        get '/projects/ecookbook/news.xml'
        
        assert_tag :tag => 'news',
          :attributes => {:type => 'array'},
          :child => {
            :tag => 'news',
            :child => {
              :tag => 'id',
              :content => '2'
            }
          }
      end
    end
    
    context ".json" do
      should_allow_api_authentication(:get, "/projects/onlinestore/news.json")
      
      should "return news" do
        get '/projects/ecookbook/news.json'
        
        json = ActiveSupport::JSON.decode(response.body)
        assert_kind_of Hash, json
        assert_kind_of Array, json['news']
        assert_kind_of Hash, json['news'].first
        assert_equal 2, json['news'].first['id']
      end
    end
  end
  
  def credentials(user, password=nil)
    ActionController::HttpAuthentication::Basic.encode_credentials(user, password || user)
  end
end
