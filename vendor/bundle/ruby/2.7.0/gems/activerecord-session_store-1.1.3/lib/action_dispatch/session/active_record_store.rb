require "active_support/core_ext/module/attribute_accessors"
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    # = Active Record Session Store
    #
    # A session store backed by an Active Record class. A default class is
    # provided, but any object duck-typing to an Active Record Session class
    # with text +session_id+ and +data+ attributes is sufficient.
    #
    # The default assumes a +sessions+ tables with columns:
    #   +id+ (numeric primary key),
    #   +session_id+ (string, usually varchar; maximum length is 255), and
    #   +data+ (text or longtext; careful if your session data exceeds 65KB).
    #
    # The +session_id+ column should always be indexed for speedy lookups.
    # Session data is marshaled to the +data+ column in Base64 format.
    # If the data you write is larger than the column's size limit,
    # ActionController::SessionOverflowError will be raised.
    #
    # You may configure the table name, primary key, and data column.
    # For example, at the end of <tt>config/application.rb</tt>:
    #
    #   ActiveRecord::SessionStore::Session.table_name = 'legacy_session_table'
    #   ActiveRecord::SessionStore::Session.primary_key = 'session_id'
    #   ActiveRecord::SessionStore::Session.data_column_name = 'legacy_session_data'
    #
    # Note that setting the primary key to the +session_id+ frees you from
    # having a separate +id+ column if you don't want it. However, you must
    # set <tt>session.model.id = session.session_id</tt> by hand!  A before filter
    # on ApplicationController is a good place.
    #
    # Since the default class is a simple Active Record, you get timestamps
    # for free if you add +created_at+ and +updated_at+ datetime columns to
    # the +sessions+ table, making periodic session expiration a snap.
    #
    # You may provide your own session class implementation, whether a
    # feature-packed Active Record or a bare-metal high-performance SQL
    # store, by setting
    #
    #   ActionDispatch::Session::ActiveRecordStore.session_class = MySessionClass
    #
    # You must implement these methods:
    #
    #   self.find_by_session_id(session_id)
    #   initialize(hash_of_session_id_and_data, options_hash = {})
    #   attr_reader :session_id
    #   attr_accessor :data
    #   save
    #   destroy
    #
    # The example SqlBypass class is a generic SQL session store. You may
    # use it as a basis for high-performance database-specific stores.
    class ActiveRecordStore < ActionDispatch::Session::AbstractStore
      # The class used for session storage. Defaults to
      # ActiveRecord::SessionStore::Session
      cattr_accessor :session_class

      SESSION_RECORD_KEY = 'rack.session.record'
      if Rack.const_defined?(:RACK_SESSION_OPTIONS)
        ENV_SESSION_OPTIONS_KEY = Rack::RACK_SESSION_OPTIONS
      else
        ENV_SESSION_OPTIONS_KEY = Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY
      end

    private
      def get_session(request, sid)
        logger.silence_logger do
          unless sid and session = @@session_class.find_by_session_id(sid)
            # If the sid was nil or if there is no pre-existing session under the sid,
            # force the generation of a new sid and associate a new session associated with the new sid
            sid = generate_sid
            session = @@session_class.new(:session_id => sid, :data => {})
          end
          request.env[SESSION_RECORD_KEY] = session
          [sid, session.data]
        end
      end

      def write_session(request, sid, session_data, options)
        logger.silence_logger do
          record = get_session_model(request, sid)
          record.data = session_data
          return false unless record.save

          session_data = record.data
          if session_data && session_data.respond_to?(:each_value)
            session_data.each_value do |obj|
              obj.clear_association_cache if obj.respond_to?(:clear_association_cache)
            end
          end

          sid
        end
      end

      def delete_session(request, session_id, options)
        logger.silence_logger do
          if sid = current_session_id(request)
            if model = @@session_class.find_by_session_id(sid)
              data = model.data
              model.destroy
            end
          end

          request.env[SESSION_RECORD_KEY] = nil

          unless options[:drop]
            new_sid = generate_sid

            if options[:renew]
              new_model = @@session_class.new(:session_id => new_sid, :data => data)
              new_model.save
              request.env[SESSION_RECORD_KEY] = new_model
            end
            new_sid
          end
        end
      end

      def get_session_model(request, id)
        logger.silence_logger do
          model = @@session_class.find_by_session_id(id)
          if !model
            id = generate_sid
            model = @@session_class.new(:session_id => id, :data => {})
            model.save
          end
          if request.env[ENV_SESSION_OPTIONS_KEY][:id].nil?
            request.env[SESSION_RECORD_KEY] = model
          else
            request.env[SESSION_RECORD_KEY] ||= model
          end
          model
        end
      end

      def find_session(request, id)
        model = get_session_model(request, id)
        [model.session_id, model.data]
      end

      def logger
        ActiveRecord::Base.logger || ActiveRecord::SessionStore::NilLogger
      end
    end
  end
end

if ActiveRecord::VERSION::MAJOR == 4
  require 'action_dispatch/session/legacy_support'
  ActionDispatch::Session::ActiveRecordStore.send(:include, ActionDispatch::Session::LegacySupport)
end
