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

module Spec
  module Models
    module Shared
      module Authorization
        def permission
          options[:permission]
        end

        def own_permission
          options[:own_permission]
        end

        def instance
          self.send(options[:instance])
        end

        def role
          self.send(options[:role])
        end

        def member
          self.send(options[:member])
        end

        def user
          self.send(options[:user])
        end

        def user_attribute
          options[:user_attribute] || :user
        end

        shared_examples "needs authorization for viewing" do |options|

          self.class_eval do
            define_method :options do
              options
            end
          end

          describe :visible do
            it "should be visible if user has the #{options[:permission]} permission in the project" do
              role.permissions = [permission]
              member.save!
              user.reload

              expect(options[:klass].visible(user)).to match_array([instance])
            end

            it "should not be visible if user lacks the #{options[:permission]} permission in the project" do
              member.save! unless permission.nil? || Redmine::AccessControl.permission(permission).public?
              instance

              expect(options[:klass].visible(user)).to match_array([])
            end
          end

          describe :visible? do
            it "should be true if the user has the #{options[:permission]} permission in the project" do
              role.permissions = [permission]
              member.save!
              user.reload

              expect(instance.visible?(user)).to be_true
            end

            it "should be false if the user lacks the #{options[:permission]} permission in the project" do
              member.save! unless permission.nil? || Redmine::AccessControl.permission(permission).public?

              expect(instance.visible?(user)).to be_false
            end
          end
        end

        shared_examples "needs authorization for editing" do |options|

          self.class_eval do
            define_method :options do
              options
            end
          end

          describe :editable? do
            it "should be editable if user has the #{options[:permission]} permission in the project" do
              role.permissions = [permission]
              member.save!
              user.reload

              expect(instance.editable?(user)).to be_true
            end

            it "should not be editable if user lacks the #{options[:permission]} permission in the project" do
              member.save! unless permission.nil? || Redmine::AccessControl.permission(permission).public?

              expect(instance.editable?(user)).to be_false
            end

            if options[:own_permission]

              it "should be editable if user has the #{options[:own_permission]} permission in the project and the #{options[:klass]} belongs to the user" do
                role.permissions = [permission]
                member.save!
                user.reload

                expect(instance.editable?(user)).to be_true
              end

              it "should not be editable if user has the #{options[:own_permission]} permission in the project and the #{options[:klass]} belongs to a different user" do
                role.permissions = [own_permission]
                member.save!
                user.reload

                instance.send(:"#{user_attribute}=", FactoryGirl.create(:user))
                instance.save!

                expect(instance.editable?(user)).to be_false
              end
            end
          end
        end

        shared_examples "needs authorization for deleting" do |options|

          self.class_eval do
            define_method :options do
              options
            end
          end

          describe :deletable? do
            it "should be deletable if user has the #{options[:permission]} permission in the project" do
              role.permissions = [permission]
              member.save!
              user.reload

              expect(instance.deletable?(user)).to be_true
            end

            it "should not be deletable if user lacks the #{options[:permission]} permission in the project" do
              member.save! unless permission.nil? || Redmine::AccessControl.permission(permission).public?

              expect(instance.deletable?(user)).to be_false
            end

            if options[:own_permission]

              it "should be deletable if user has the #{options[:own_permission]} permission in the project and the message belongs to the user" do
                role.permissions = [own_permission]
                member.save!
                user.reload

                expect(instance.deletable?(user)).to be_true
              end

              it "should not be deletable if user has the #{options[:own_permission]} permission in the project and the message belongs to a different user" do
                role.permissions = [own_permission]
                member.save!
                user.reload

                instance.send(:"#{user_attribute}=", FactoryGirl.create(:user))
                instance.save!

                expect(instance.deletable?(user)).to be_false
              end
            end
          end
        end
      end
    end
  end
end
