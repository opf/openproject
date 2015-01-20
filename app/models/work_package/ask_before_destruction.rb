#-- encoding: UTF-8
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

module WorkPackage::AskBeforeDestruction
  extend ActiveSupport::Concern

  DestructionRegistration = Struct.new(:klass, :check, :action)

  def self.included(base)
    base.extend(ClassMethods)

    base.class_attribute :registered_associated_to_ask_before_destruction
  end

  module ClassMethods
    def cleanup_action_required_before_destructing?(work_packages)
      !associated_to_ask_before_destruction_of(work_packages).empty?
    end

    def cleanup_associated_before_destructing_if_required(work_packages, user, to_do = { action: 'destroy' })
      cleanup_required = cleanup_action_required_before_destructing?(work_packages)

      (!cleanup_required ||
       (cleanup_required &&
        cleanup_each_associated_class(work_packages, user, to_do)))
    end

    def associated_classes_to_address_before_destruction_of(work_packages)
      associated = []

      registered_associated_to_ask_before_destruction.each do |registration|
        associated << registration.klass if registration.check.call(work_packages)
      end

      associated
    end

    private

    def associated_to_ask_before_destruction_of(work_packages)
      associated = {}

      registered_associated_to_ask_before_destruction.each do |registration|
        associated[registration.klass] = registration.action if registration.check.call(work_packages)
      end

      associated
    end

    def associated_to_ask_before_destruction(klass, check, action)
      self.registered_associated_to_ask_before_destruction ||= []

      registration = DestructionRegistration.new(klass, check, action)

      self.registered_associated_to_ask_before_destruction << registration
    end

    def cleanup_each_associated_class(work_packages, user, to_do)
      ret = false

      transaction do
        associated_to_ask_before_destruction_of(work_packages).each do |_klass, method|
          ret = method.call(work_packages, user, to_do)
        end

        raise ActiveRecord::Rollback unless ret
      end

      ret
    end
  end
end
