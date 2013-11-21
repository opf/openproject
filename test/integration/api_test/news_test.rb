#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../test_helper', __FILE__)

class ApiTest::NewsTest < ActionDispatch::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
  end

  context "GET /api/v1/news" do
    context ".xml" do
      should "return news" do
        get '/api/v1/news.xml'

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
        get '/api/v1/news.json'

        json = ActiveSupport::JSON.decode(response.body)
        assert_kind_of Hash, json
        assert_kind_of Array, json['news']
        assert_kind_of Hash, json['news'].first
        assert_equal 2, json['news'].first['id']
      end
    end
  end

  context "GET /api/v1/projects/:project_id/news" do
    context ".xml" do
      should_allow_api_authentication(:get, "/api/v1/projects/onlinestore/news.xml")

      should "return news" do
        get '/api/v1/projects/ecookbook/news.xml'

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
      should_allow_api_authentication(:get, "/api/v1/projects/onlinestore/news.json")

      should "return news" do
        get '/api/v1/projects/ecookbook/news.json'

        json = ActiveSupport::JSON.decode(response.body)
        assert_kind_of Hash, json
        assert_kind_of Array, json['news']
        assert_kind_of Hash, json['news'].first
        assert_equal 2, json['news'].first['id']
      end
    end
  end
end
