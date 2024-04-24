#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Exports
  class Register
    class << self
      attr_reader :lists, :singles, :formatters

      def register(&)
        instance_exec(&)
      end

      def list(model, exporter)
        @lists ||= Hash.new do |hash, model_key|
          hash[model_key] = []
        end

        @lists[model.to_s] << exporter unless @lists[model.to_s].include?(exporter)
      end

      def list_formats(model)
        lists[model.to_s].map(&:key)
      end

      def single(model, exporter)
        @singles ||= Hash.new do |hash, model_key|
          hash[model_key] = []
        end

        @singles[model.to_s] << exporter unless @singles[model.to_s].include?(exporter)
      end

      def single_formats(model)
        singles[model.to_s].map(&:key)
      end

      def formatter(model, formatter)
        @formatters ||= Hash.new do |hash, model_key|
          hash[model_key] = []
        end

        @formatters[model.to_s] << formatter
      end

      def list_exporter(model, format)
        lists[model.to_s].detect { |exporter| exporter.key == format }
      end

      def single_exporter(model, format)
        singles[model.to_s].detect { |exporter| exporter.key == format }
      end

      def formatter_for(model, attribute, export_format)
        formatter = formatters[model.to_s].find { |f| f.apply? attribute, export_format } || ::Exports::Formatters::Default
        formatter.new(attribute)
      end
    end
  end
end
