#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

module API
  module Errors
    class Unauthenticated < Grape::Exceptions::Base
      attr_reader :code, :title, :description, :headers

      def initialize(args = { })
        @code = args[:code] || 401
        @title = args[:title] || 'not_authenticated'
        @description = args[:description] || 'User needs to be authenticated to access this resource.'
        @headers = { 'Content-Type' => 'application/hal+json' }.merge(args[:headers] || { })
      end

      def errors
        [{ key: @title, messages: ['You need to be authenticated to access this resource'] }]
      end

      def to_json
        { title: @title, description: @description, errors: errors }.to_json
      end
    end
  end
end
