#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require 'enumerator'

module TimelinesCollectionProxy
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def collection_proxy(name, options)
      options.assert_valid_keys(:for, :leave_public)

      relation_names = options[:for]

      proxy_class = Class.new(TimelinesCollectionProxy::Proxy)
      proxy_class.class_eval(&Proc.new) if block_given?

      define_method name do
        proxy_class.new(relation_names.map { |n| send(n) }, self)
      end

      protected(*relation_names) unless options[:leave_public]
    end
  end

  class Proxy
    include Enumerable

    attr_reader :proxy_owner

    def initialize(proxies, proxy_owner)
      @proxies = proxies
      @proxy_owner = proxy_owner
    end

    def blank?
      @proxies.all?(&:blank?)
    end

    def present?
      @proxies.any?(&:present?)
    end

    def empty?
      @proxies.all?(&:empty?)
    end

    def to_ary
      @proxies.map(&:to_a).flatten(1)
    end
    alias_method :to_a, :to_ary
    alias_method :all,  :to_ary

    def find(*args, &block)
      found = nil
      error = nil

      @proxies.each do |proxy|
        begin
          result = proxy.find(*args, &block)

          case result
          when nil
            # do nothing - especially do not overwrite previous results
          when Enumerable
            found += result
          else
            found = result
          end

          # If somebody uses :first and :last, s/he will get strange results.
          # Let's fix it, when it happens
          break if found.present? and found.is_a?(Enumerable)

        rescue ActiveRecord::RecordNotFound
          error = $!
        end
      end

      raise error if found.blank? and error.present?

      found
    end

    def first
      @proxies.find(&:first).first
    end

    def last
      @proxies.reverse.find(&:last).last
    end

    def each(*args, &block)
      @proxies.each do |proxy|
        proxy.each(*args, &block)
      end
    end

    def count
      @proxies.inject(0) { |akku, proxy| akku + proxy.count }
    end

    def length
      @proxies.inject(0) { |akku, proxy| akku + proxy.length }
    end

    def size
      @proxies.inject(0) { |akku, proxy| akku + proxy.size }
    end

    %w[build create << delete delete_all replace push].each do |method|
      class_eval %{
        def #{method}(*args)
          raise NotImplementedError, 'This proxy is read-only'
        end
      }
    end
  end
end
