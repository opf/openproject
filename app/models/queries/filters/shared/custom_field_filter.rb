#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Queries::Filters::Shared::CustomFieldFilter
  def self.included(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)

    base.class_eval do
      attr_accessor :custom_field
      validate :custom_field_valid

      class_attribute :custom_field_context
    end
  end

  module InstanceMethods
    def error_messages
      messages = errors
                 .full_messages
                 .join(" #{I18n.t('support.array.sentence_connector')} ")

      human_name + I18n.t(default: ' %<message>s', message: messages)
    end

    private

    def type_strategy
      @type_strategy ||= (strategies[type] || strategies[:inexistent]).new(self)
    end

    def custom_field_valid
      if custom_field.nil?
        errors.add(:base, I18n.t('activerecord.errors.models.query.filters.custom_fields.inexistent'))
      elsif invalid_custom_field_for_context?
        errors.add(:base, I18n.t('activerecord.errors.models.query.filters.custom_fields.invalid'))
      end
    end

    def validate_inclusion_of_operator
      super if custom_field
    end

    def invalid_custom_field_for_context?
      project && invalid_custom_field_for_project? ||
        !project && invalid_custom_field_globally?
    end

    def invalid_custom_field_globally?
      !self.class.custom_fields(project)
           .exists?(custom_field.id)
    end

    def invalid_custom_field_for_project?
      !self.class.custom_fields(project)
           .map(&:id).include? custom_field.id
    end

    def strategies
      strategies = Queries::Filters::STRATEGIES.dup
      strategies[:list_optional] = Queries::Filters::Strategies::CfListOptional
      strategies[:integer] = Queries::Filters::Strategies::CfInteger
      # knowing that only bool have list type
      strategies[:list] = Queries::Filters::Strategies::BooleanList

      strategies
    end
  end

  module ClassMethods
    def key
      /cf_(\d+)/
    end

    ##
    # TODO this differs from CustomField#accessor_name for reasons I don't see,
    # however this name will be persisted in queries so we can't just map one to the other.
    def custom_field_accessor(custom_field)
      "cf_#{custom_field.id}"
    end

    def all_for(context = nil)
      custom_field_context.custom_fields(context).map do |cf|
        cf_name = custom_field_accessor(cf)
        begin
          create!(cf_name, { custom_field: cf })
        rescue ::Queries::Filters::InvalidError => e
          Rails.logger.error "Failed to map custom field filter for #{name} (CF##{cf.id}."
          nil
        end
      end.compact
    end

    ##
    # Find the given custom field by its accessor, should it exist.
    def find_by_accessor(name)
      match = name.match /(custom_field_|cf_)(\d+)/

      if match.present? && match[2].to_i > 0
        custom_field_context.custom_field_class.find_by(id: match[2])
      end

      nil
    end

    ##
    # Create a filter instance for the given custom field accesor
    def create!(cf_name, options = {})
      custom_field = options.delete(:custom_field) { find_by_accessor(cf_name) }
      raise ::Queries::Filters::InvalidError if custom_field.nil?

      new_for_custom_field(cf_name, custom_field, options)
    end

    ##
    # Create a new custom field subfilter for the given custom field
    def new_for_custom_field(name, custom_field, options)
      constant_name = subfilter_module(custom_field)
      clazz = "::Queries::Filters::Shared::CustomFields::#{constant_name}".constantize
      clazz.create!(custom_field, custom_field_context, options)
    rescue NameError => e
      Rails.logger.error "Failed to constantize custom field filter for #{name}. #{e}"
      raise ::Queries::Filters::InvalidError
    end

    ##
    # Get the subfilter class name for the given custom field
    def subfilter_module(custom_field)
      case custom_field.field_format
      when 'user'
        :User
      when 'list', 'version'
        :ListOptional
      when 'bool'
        :Bool
      else
        :Base
      end
    end
  end
end
