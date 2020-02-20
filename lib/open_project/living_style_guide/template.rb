#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module LivingStyleGuide
    class Template < SassC::Rails::SassTemplate
      attr_accessor :filename
      attr_accessor :data

      def initialize(filename, options = {}, &block)
        self.filename = filename
        self.data = yield.gsub(/\n/, '')

        super(options, &block)
      end

      def render(scope = nil, *)
        engine = ::SassC::Engine.new(data, engine_options(scope))

        Sprockets::Utils.module_include(::SassC::Script::Functions, @functions) do
          engine.render
        end
      end

      def engine_options(scope)
        {
          filename: filename,
          line_comments: line_comments?,
          syntax: self.class.syntax,
          load_paths: scope.environment.paths,
          importer: SassC::Rails::Importer,
          sprockets: {
            context: scope,
            environment: scope.environment,
            dependencies: scope.metadata[:dependency_paths]
          }
        }.merge!(config_options) { |key, left, right| safe_merge(key, left, right) }
      end
    end
  end
end
