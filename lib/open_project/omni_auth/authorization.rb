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

module OpenProject
  module OmniAuth
    ##
    # Provides authorization mechanisms for OmniAuth-based authentication.
    module Authorization
      ##
      # Checks whether the given user is authorized to login by calling
      # all registered callbacks. If all callbacks approve the user is authorized and may log in.
      def self.authorized?(auth_hash)
        rejection = callbacks.find_map { |callback|
          d = callback.authorize auth_hash

          if d.is_a? Decision
            d if d.reject?
          else
            fail ArgumentError, 'Expecting Callback#authorize to return a Decision.'
          end
        }

        rejection || Approval.new
      end

      ##
      # Signals that the given user has been logged in.
      #
      # Note: Only call if you know what you are doing.
      def self.after_login!(user, auth_hash, context = self)
        after_login_callbacks.each do |callback|
          callback.after_login user, auth_hash, context
        end
      end

      ##
      # Adds a callback to be executed before a user is logged in.
      # The given callback may reject the user to prevent authorization by
      # calling dec#reject(error) or approve by calling dec#approve.
      #
      # If not approved a user is implicitly rejected.
      #
      # @param opts [Hash] options for the callback registration
      # @option opts [Symbol] :provider Only call for given provider
      #
      # @yield [decision, user, auth_hash] Callback to be executed before the user is logged in.
      # @yieldparam [DecisionStore] dec object providing #approve and #reject
      # @yieldparam [User] user The OpenProject user to be logged in.
      # @yieldparam [AuthHash] OmniAuth authentication information including user info
      #                        and credentials.
      # @yieldreturn [Decision] A Decision indicating whether or not to authorize the user.
      def self.authorize_user(opts = {}, &block)
        if opts[:provider]
          authorize_user_for_provider opts[:provider], &block
        else
          add_authorize_user_callback AuthorizationBlockCallback.new(&block)
        end
      end

      def self.authorize_user_for_provider(provider, &block)
        callback = AuthorizationBlockCallback.new do |dec, auth_hash|
          if auth_hash.provider.to_sym == provider.to_sym
            block.call dec, auth_hash
          else
            dec.approve
          end
        end

        add_authorize_user_callback callback
      end

      ##
      # Registers a callback on the event of a successful login.
      #
      # Called directly after logging in.
      # This usually happens when the user logged in normally or was logged in
      # automatically after on-the-fly registration via automated account activation.
      #
      # @yield [user] Callback called with the successfully logged in user.
      # @yieldparam user [User] User who has been logged in.
      # @yieldparam auth_hash [AuthHash] auth_hash OmniAuth authentication information
      #                                  including user info and credentials.
      # @yieldparam context The context from which the callback is called, e.g. a Controller.                    
      def self.after_login(&block)
        add_after_login_callback AfterLoginBlockCallback.new(&block)
      end

      ##
      # Registers a new callback to decide whether or not a user is to be authorized.
      #
      # @param [AuthorizationCallback] Callback to be called upon user authorization.
      def self.add_authorize_user_callback(callback)
        callbacks << callback
      end

      def self.callbacks
        @callbacks ||= []
      end

      ##
      # Registers a new callback to successful user login.
      #
      # @param [AfterLoginCallback] Callback to be called upon successful authorization.
      def self.add_after_login_callback(callback)
        after_login_callbacks << callback
      end

      def self.after_login_callbacks
        @after_login_callbacks ||= []
      end

      ##
      # Performs user authorization.
      class AuthorizationCallback
        ##
        # Given an OmniAuth auth hash this decides if a user is authorized or not.
        #
        # @param [AuthHash] auth_hash OmniAuth authentication information including user info
        #                   and credentials.
        #
        # @return [Decision] A decision indicating whether the user is authorized or not.
        def authorize(auth_hash)
          fail "subclass responsibility: authorize(#{auth_hash})"
        end
      end

      ##
      # A callback triggering a given block.
      class AuthorizationBlockCallback < AuthorizationCallback
        attr_reader :block

        def initialize(&block)
          @block = block
        end

        def authorize(auth_hash)
          store = DecisionStore.new
          block.call store, auth_hash
          # failure to make a decision results in a rejection
          store.decision || Rejection.new(I18n.t('user.authorization_rejected'))
        end
      end

      ##
      # A callback for reacting to a user being logged in.
      class AfterLoginCallback
        ##
        # Is called after a user has been logged in successfully.
        #
        # @param [User] User who has been logged in.
        # @param [Omniauth::AuthHash] Omniauth authentication info including credentials.
        def after_login(user, auth_hash, context)
          fail "subclass responsibility: after_login(#{user}, #{auth_hash}, #{context})"
        end
      end

      ##
      # A after_login callback triggering a given block.
      class AfterLoginBlockCallback < AfterLoginCallback
        attr_reader :block

        def initialize(&block)
          @block = block
        end

        def after_login(user, auth_hash, context)
          block.call user, auth_hash, context
        end
      end

      ##
      # Abstract base class for an authorization decision.
      # Any subclass must either override #approve? or #reject?
      # the both of which are defined in terms of each other.
      class Decision
        def approve?
          !reject?
        end

        def reject?
          !approve?
        end

        def self.approve
          Approval.new
        end

        def self.reject(error_message)
          Rejection.new error_message
        end
      end

      ##
      # Indicates a rejected authorization attempt.
      class Rejection < Decision
        attr_reader :message

        def initialize(message)
          @message = message
        end

        def reject?
          true
        end
      end

      ##
      # Indicates an approved authorization.
      class Approval < Decision
        def approve?
          true
        end
      end

      ##
      # Stores a decision.
      class DecisionStore
        attr_accessor :decision

        def approve
          self.decision = Approval.new
        end

        def reject(error_message)
          self.decision = Rejection.new error_message
        end
      end

      Enumerable.class_eval do
        ##
        # Passes each element to the given block and returns the
        # result of the block as soon as it's truthy.
        def find_map(&block)
          each do |e|
            result = block.call e

            return result if result
          end

          nil
        end
      end
    end
  end
end
