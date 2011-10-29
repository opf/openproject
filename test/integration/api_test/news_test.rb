#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../test_helper', __FILE__)
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
