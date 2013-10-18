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


# Provides some convenience for copying an ActiveRecord model with associations.
# The actual copying methods need to be provided, though.
# Including this Module will include Redmine::SafeAttributes as well.
module CopyModel
  module InstanceMethods

    # Copies all attributes from +from_model+
    # except those specified in self.class#not_to_copy.
    # Does NOT save self.
    def copy_attributes(from_model)
      with_model(from_model) do |model|
        # clear unique attributes
        self.safe_attributes = model.attributes.dup.except(*self.class.not_to_copy)
        return self
      end
    end

    # Copies the instance's associations based on the +from_model+.
    # The associations CAN be copied when the instance responds to 
    # something called 'copy_association_name'.
    #
    # For example: If we have a method called #copy_work_packages,
    #              the WorkPackages from the work_packages association can be copied.
    #
    # Accepts an +options+ argument to specify what to copy
    #
    # Examples:
    #   model.copy_associations(1)                                    # => copies everything
    #   model.copy_associations(1, :only => 'members')                # => copies members only
    #   model.copy_associations(1, :only => ['members', 'versions'])  # => copies members and versions
    def copy_associations(from_model, options={})
      to_be_copied = self.class.reflect_on_all_associations.map(&:name)
      to_be_copied = options[:only].to_a unless options[:only].nil?
      to_be_copied = to_be_copied.map(&:to_s).sort do |a,b|
        (self.copy_precedence.index(a) || -1) <=> (self.copy_precedence.index(b) || -1)
      end.map(&:to_sym)

      with_model(from_model) do |model|
        self.class.transaction do

          to_be_copied.each do |name|
            if (self.respond_to?(:"copy_#{name}") || self.private_methods.include?(:"copy_#{name}"))
              self.reload
              self.send(:"copy_#{name}", model)
            end
          end
          self
        end
      end
    end

    # copies everything (associations and attributes) based on
    # +from_model+ and saves the instance.
    def copy(from_model, options = {})
      self.save if (self.copy_attributes(from_model) && self.copy_associations(from_model, options))
      return self
    end

    # resolves +model+ and returns it,
    # or yields it if a block was passed
    def with_model(model)
      model = model.is_a?(self.class) ? model : self.class.find(model)
      if model
        if block_given?
          yield model
        else
          return model
        end
      else
        nil
      end
    end

    def copy_precedence
      self.class.copy_precedence
    end
  end

  module ClassMethods

    # Overwrite or set CLASS::NOT_TO_COPY to specify
    # which attributes are not safe to copy.
    def not_to_copy
      begin
        self::NOT_TO_COPY
      rescue NameError
        []
      end
    end

    def copy_precedence
      begin
        self::COPY_PRECEDENCE
      rescue NameError
        []
      end
    end

    # Copies +from_model+ and returns the new instance. This will not save
    # the copy
    def copy_attributes(from_model)
      return self.new.copy_attributes(from_model)
    end

    # Creates a new instance and
    # copies everything (associations and attributes) based on
    # +from_model+.
    def copy(from_model, options = {})
      self.new.copy(from_model, options)
    end
  end

  def self.included(base)
    base.send :extend,  self::ClassMethods
    base.send :include, self::InstanceMethods
    base.send :include, Redmine::SafeAttributes

  end

  def self.extended(base)
    base.send :extend,  self::ClassMethods
    base.send :include, self::InstanceMethods
    base.send :include, Redmine::SafeAttributes
  end
end
