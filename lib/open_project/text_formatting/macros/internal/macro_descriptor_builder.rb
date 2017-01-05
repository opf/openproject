#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

module OpenProject::TextFormatting::Macros::Internal
  class MacroDescriptorBuilder
    require 'open_project/text_formatting/macros/macro_descriptor'

    def id(value)
      @id = value.to_sym
    end

    def prefix(value)
      @prefix = value.to_sym
    end

    def desc(value)
      @desc = value.strip
    end

    def param(&block)
      (@params ||= []) << ParamDescriptorBuilder.build(&block)
    end

    def legacy_support(&block)
      @legacy_support = LegacySupportDescriptorBuilder.build(&block)
    end

    def stateful
      @stateful = true
    end

    def post_process
      @post_process = true
    end

    def legacy
      @legacy = true
    end

    def meta(&block)
      @meta = MetaDescriptorBuilder.build &block
    end

    def self.build(&block)
      unless block_given?
        raise 'Block required.'
      end
      instance = MacroDescriptorBuilder.new
      instance.instance_eval &block
      #validate
      make_descriptor instance
    end

    def self.make_descriptor(instance)
      instance.instance_eval do
        OpenProject::TextFormatting::Macros::MacroDescriptor.new(
          prefix: @prefix,
          id: @id,
          desc: @desc,
          params: @params,
          meta: @meta || {},
          legacy_support: @legacy_support,
          legacy: @legacy,
          stateful: @stateful,
          post_process: @post_process
        )
      end
    end
  end

  class ParamDescriptorBuilder
    def id(value)
      @id = value
    end

    def desc(value)
      @desc = value.strip
    end

    def default(value)
      @default = value
    end

    def optional
      @optional = true
    end

    def one_of(*values)
      @one_of = values
    end

    def boolean
      @type = :boolean
    end

    # protected

    def self.build(&block)
      unless block_given?
        raise 'Block required.'
      end
      instance = ParamDescriptorBuilder.new
      instance.instance_eval &block
      validate instance
      make_descriptor instance
    end

    def self.validate(instance)
      instance.instance_eval do
        raise 'No id given' if @id.nil? or @id.blank?
      end
    end

    def self.make_descriptor(instance)
      instance.instance_eval do
        {
          id: @id,
          desc: @desc,
          optional: @optional,
          default: @default,
          one_of: @one_of,
          type: @type || :string
        }
      end
    end
  end

  class LegacySupportDescriptorBuilder
    def id(value)
      @id = value
    end

    # protected

    def self.build(&block)
      instance = LegacySupportDescriptorBuilder.new
      if block_given?
        instance.instance_eval &block
        validate instance
      end
      make_descriptor instance
    end

    def self.validate(instance)
      instance.instance_eval do
        unless @id.nil?
          raise 'No id given' if @id.blank?
        end
      end
    end

    def self.make_descriptor(instance)
      instance.instance_eval do
        result = {}
        unless @id.nil?
          result[:id] = @id
        end
        result
      end
    end
  end

  class MetaDescriptorBuilder
    def provider(value)
      @provider = value
    end

    def url(value)
      @url = value
    end

    def version(value)
      @version = value
    end

    def issues(value)
      @issues = value
    end

    def self.build(&block)
      unless block_given?
        raise 'Block required.'
      end
      instance = MetaDescriptorBuilder.new
      instance.instance_eval &block
      validate instance
      make_descriptor instance
    end

    def self.validate(instance)
      instance.instance_eval do
        errors = []
        errors << 'A provider must be specified' if @provider.nil? or @provider.blank?
        errors << 'A url must be specified' if @url.nil? or @url.blank?
        raise errors unless errors.empty?
      end
    end

    def self.make_descriptor(instance)
      instance.instance_eval do
        {
          provider: @provider,
          url: @url,
          issues: @issues,
          version: @version
        }
      end
    end
  end
end
