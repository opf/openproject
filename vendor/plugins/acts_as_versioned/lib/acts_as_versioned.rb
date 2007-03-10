# Copyright (c) 2005 Rick Olson
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    # Specify this act if you want to save a copy of the row in a versioned table.  This assumes there is a 
    # versioned table ready and that your model has a version field.  This works with optimisic locking if the lock_version
    # column is present as well.
    #
    # The class for the versioned model is derived the first time it is seen. Therefore, if you change your database schema you have to restart
    # your container for the changes to be reflected. In development mode this usually means restarting WEBrick.
    #
    #   class Page < ActiveRecord::Base
    #     # assumes pages_versions table
    #     acts_as_versioned
    #   end
    #
    # Example:
    #
    #   page = Page.create(:title => 'hello world!')
    #   page.version       # => 1
    #
    #   page.title = 'hello world'
    #   page.save
    #   page.version       # => 2
    #   page.versions.size # => 2
    #
    #   page.revert_to(1)  # using version number
    #   page.title         # => 'hello world!'
    #
    #   page.revert_to(page.versions.last) # using versioned instance
    #   page.title         # => 'hello world'
    #
    # See ActiveRecord::Acts::Versioned::ClassMethods#acts_as_versioned for configuration options
    module Versioned
      CALLBACKS = [:set_new_version, :save_version_on_create, :save_version?, :clear_changed_attributes]
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        # == Configuration options
        #
        # * <tt>class_name</tt> - versioned model class name (default: PageVersion in the above example)
        # * <tt>table_name</tt> - versioned model table name (default: page_versions in the above example)
        # * <tt>foreign_key</tt> - foreign key used to relate the versioned model to the original model (default: page_id in the above example)
        # * <tt>inheritance_column</tt> - name of the column to save the model's inheritance_column value for STI.  (default: versioned_type)
        # * <tt>version_column</tt> - name of the column in the model that keeps the version number (default: version)
        # * <tt>sequence_name</tt> - name of the custom sequence to be used by the versioned model.
        # * <tt>limit</tt> - number of revisions to keep, defaults to unlimited
        # * <tt>if</tt> - symbol of method to check before saving a new version.  If this method returns false, a new version is not saved.
        #   For finer control, pass either a Proc or modify Model#version_condition_met?
        #
        #     acts_as_versioned :if => Proc.new { |auction| !auction.expired? }
        #
        #   or...
        #
        #     class Auction
        #       def version_condition_met? # totally bypasses the <tt>:if</tt> option
        #         !expired?
        #       end
        #     end
        #
        # * <tt>if_changed</tt> - Simple way of specifying attributes that are required to be changed before saving a model.  This takes
        #   either a symbol or array of symbols.  WARNING - This will attempt to overwrite any attribute setters you may have.  
        #   Use this instead if you want to write your own attribute setters (and ignore if_changed):
        # 
        #     def name=(new_name)
        #       write_changed_attribute :name, new_name
        #     end
        #
        # * <tt>extend</tt> - Lets you specify a module to be mixed in both the original and versioned models.  You can also just pass a block
        #   to create an anonymous mixin:
        #
        #     class Auction
        #       acts_as_versioned do
        #         def started?
        #           !started_at.nil?
        #         end
        #       end
        #     end
        #
        #   or...
        #
        #     module AuctionExtension
        #       def started?
        #         !started_at.nil?
        #       end
        #     end
        #     class Auction
        #       acts_as_versioned :extend => AuctionExtension
        #     end
        #
        #  Example code:
        #
        #    @auction = Auction.find(1)
        #    @auction.started?
        #    @auction.versions.first.started?
        #
        # == Database Schema
        #
        # The model that you're versioning needs to have a 'version' attribute. The model is versioned 
        # into a table called #{model}_versions where the model name is singlular. The _versions table should 
        # contain all the fields you want versioned, the same version column, and a #{model}_id foreign key field.
        #
        # A lock_version field is also accepted if your model uses Optimistic Locking.  If your table uses Single Table inheritance,
        # then that field is reflected in the versioned model as 'versioned_type' by default.
        #
        # Acts_as_versioned comes prepared with the ActiveRecord::Acts::Versioned::ActMethods::ClassMethods#create_versioned_table 
        # method, perfect for a migration.  It will also create the version column if the main model does not already have it.
        #
        #   class AddVersions < ActiveRecord::Migration
        #     def self.up
        #       # create_versioned_table takes the same options hash
        #       # that create_table does
        #       Post.create_versioned_table
        #     end
        #   
        #     def self.down
        #       Post.drop_versioned_table
        #     end
        #   end
        # 
        # == Changing What Fields Are Versioned
        #
        # By default, acts_as_versioned will version all but these fields: 
        # 
        #   [self.primary_key, inheritance_column, 'version', 'lock_version', versioned_inheritance_column]
        #
        # You can add or change those by modifying #non_versioned_columns.  Note that this takes strings and not symbols.
        #
        #   class Post < ActiveRecord::Base
        #     acts_as_versioned
        #     self.non_versioned_columns << 'comments_count'
        #   end
        # 
        def acts_as_versioned(options = {}, &extension)
          # don't allow multiple calls
          return if self.included_modules.include?(ActiveRecord::Acts::Versioned::ActMethods)

          send :include, ActiveRecord::Acts::Versioned::ActMethods
          
          cattr_accessor :versioned_class_name, :versioned_foreign_key, :versioned_table_name, :versioned_inheritance_column, 
            :version_column, :max_version_limit, :track_changed_attributes, :version_condition, :version_sequence_name, :non_versioned_columns,
            :version_association_options
            
          # legacy
          alias_method :non_versioned_fields,  :non_versioned_columns
          alias_method :non_versioned_fields=, :non_versioned_columns=

          class << self
            alias_method :non_versioned_fields,  :non_versioned_columns
            alias_method :non_versioned_fields=, :non_versioned_columns=
          end

          send :attr_accessor, :changed_attributes

          self.versioned_class_name         = options[:class_name]  || "Version"
          self.versioned_foreign_key        = options[:foreign_key] || self.to_s.foreign_key
          self.versioned_table_name         = options[:table_name]  || "#{table_name_prefix}#{base_class.name.demodulize.underscore}_versions#{table_name_suffix}"
          self.versioned_inheritance_column = options[:inheritance_column] || "versioned_#{inheritance_column}"
          self.version_column               = options[:version_column]     || 'version'
          self.version_sequence_name        = options[:sequence_name]
          self.max_version_limit            = options[:limit].to_i
          self.version_condition            = options[:if] || true
          self.non_versioned_columns        = [self.primary_key, inheritance_column, 'version', 'lock_version', versioned_inheritance_column]
          self.version_association_options  = {
                                                :class_name  => "#{self.to_s}::#{versioned_class_name}",
                                                :foreign_key => "#{versioned_foreign_key}",
                                                :order       => 'version',
                                                :dependent   => :delete_all
                                              }.merge(options[:association_options] || {})

          if block_given?
            extension_module_name = "#{versioned_class_name}Extension"
            silence_warnings do
              self.const_set(extension_module_name, Module.new(&extension))
            end
            
            options[:extend] = self.const_get(extension_module_name)
          end

          class_eval do
            has_many :versions, version_association_options
            before_save  :set_new_version
            after_create :save_version_on_create
            after_update :save_version
            after_save   :clear_old_versions
            after_save   :clear_changed_attributes
            
            unless options[:if_changed].nil?
              self.track_changed_attributes = true
              options[:if_changed] = [options[:if_changed]] unless options[:if_changed].is_a?(Array)
              options[:if_changed].each do |attr_name|
                define_method("#{attr_name}=") do |value|
                  write_changed_attribute attr_name, value
                end
              end
            end
            
            include options[:extend] if options[:extend].is_a?(Module)
          end

          # create the dynamic versioned model
          const_set(versioned_class_name, Class.new(ActiveRecord::Base)).class_eval do
            def self.reloadable? ; false ; end
          end
          
          versioned_class.set_table_name versioned_table_name
          versioned_class.belongs_to self.to_s.demodulize.underscore.to_sym, 
            :class_name  => "::#{self.to_s}", 
            :foreign_key => versioned_foreign_key
          versioned_class.send :include, options[:extend]         if options[:extend].is_a?(Module)
          versioned_class.set_sequence_name version_sequence_name if version_sequence_name
        end
      end
    
      module ActMethods
        def self.included(base) # :nodoc:
          base.extend ClassMethods
        end
        
        # Saves a version of the model if applicable
        def save_version
          save_version_on_create if save_version?
        end
        
        # Saves a version of the model in the versioned table.  This is called in the after_save callback by default
        def save_version_on_create
          rev = self.class.versioned_class.new
          self.clone_versioned_model(self, rev)
          rev.version = send(self.class.version_column)
          rev.send("#{self.class.versioned_foreign_key}=", self.id)
          rev.save
        end

        # Clears old revisions if a limit is set with the :limit option in <tt>acts_as_versioned</tt>.
        # Override this method to set your own criteria for clearing old versions.
        def clear_old_versions
          return if self.class.max_version_limit == 0
          excess_baggage = send(self.class.version_column).to_i - self.class.max_version_limit
          if excess_baggage > 0
            sql = "DELETE FROM #{self.class.versioned_table_name} WHERE version <= #{excess_baggage} AND #{self.class.versioned_foreign_key} = #{self.id}"
            self.class.versioned_class.connection.execute sql
          end
        end

        # Finds a specific version of this model.
        def find_version(version)
          return version if version.is_a?(self.class.versioned_class)
          return nil if version.is_a?(ActiveRecord::Base)
          find_versions(:conditions => ['version = ?', version], :limit => 1).first
        end
        
        # Finds versions of this model.  Takes an options hash like <tt>find</tt>
        def find_versions(options = {})
          versions.find(:all, options)
        end

        # Reverts a model to a given version.  Takes either a version number or an instance of the versioned model
        def revert_to(version)
          if version.is_a?(self.class.versioned_class)
            return false unless version.send(self.class.versioned_foreign_key) == self.id and !version.new_record?
          else
            return false unless version = find_version(version)
          end
          self.clone_versioned_model(version, self)
          self.send("#{self.class.version_column}=", version.version)
          true
        end

        # Reverts a model to a given version and saves the model.  
        # Takes either a version number or an instance of the versioned model
        def revert_to!(version)
          revert_to(version) ? save_without_revision : false
        end

        # Temporarily turns off Optimistic Locking while saving.  Used when reverting so that a new version is not created.
        def save_without_revision
          save_without_revision!
          true
        rescue
          false
        end

        def save_without_revision!
          without_locking do
            without_revision do
              save!
            end
          end
        end

        # Returns an array of attribute keys that are versioned.  See non_versioned_columns
        def versioned_attributes
          self.attributes.keys.select { |k| !self.class.non_versioned_columns.include?(k) }
        end
        
        # If called with no parameters, gets whether the current model has changed and needs to be versioned.
        # If called with a single parameter, gets whether the parameter has changed.
        def changed?(attr_name = nil)
          attr_name.nil? ?
            (!self.class.track_changed_attributes || (changed_attributes && changed_attributes.length > 0)) :
            (changed_attributes && changed_attributes.include?(attr_name.to_s))
        end
        
        # keep old dirty? method
        alias_method :dirty?, :changed?
        
        # Clones a model.  Used when saving a new version or reverting a model's version.
        def clone_versioned_model(orig_model, new_model)
          self.versioned_attributes.each do |key|
            new_model.send("#{key}=", orig_model.attributes[key]) if orig_model.has_attribute?(key)
          end
          
          if orig_model.is_a?(self.class.versioned_class)
            new_model[new_model.class.inheritance_column] = orig_model[self.class.versioned_inheritance_column]
          elsif new_model.is_a?(self.class.versioned_class)
            new_model[self.class.versioned_inheritance_column] = orig_model[orig_model.class.inheritance_column]
          end
        end
        
        # Checks whether a new version shall be saved or not.  Calls <tt>version_condition_met?</tt> and <tt>changed?</tt>.
        def save_version?
          version_condition_met? && changed?
        end
        
        # Checks condition set in the :if option to check whether a revision should be created or not.  Override this for
        # custom version condition checking.
        def version_condition_met?
          case
          when version_condition.is_a?(Symbol)
            send(version_condition)
          when version_condition.respond_to?(:call) && (version_condition.arity == 1 || version_condition.arity == -1)
            version_condition.call(self)
          else
            version_condition
          end          
        end

        # Executes the block with the versioning callbacks disabled.
        #
        #   @foo.without_revision do
        #     @foo.save
        #   end
        #
        def without_revision(&block)
          self.class.without_revision(&block)
        end

        # Turns off optimistic locking for the duration of the block
        #
        #   @foo.without_locking do
        #     @foo.save
        #   end
        #
        def without_locking(&block)
          self.class.without_locking(&block)
        end

        def empty_callback() end #:nodoc:

        protected          
          # sets the new version before saving, unless you're using optimistic locking.  In that case, let it take care of the version.
          def set_new_version
            self.send("#{self.class.version_column}=", self.next_version) if new_record? || (!locking_enabled? && save_version?)
          end
          
          # Gets the next available version for the current record, or 1 for a new record
          def next_version
            return 1 if new_record?
            (versions.calculate(:max, :version) || 0) + 1
          end
          
          # clears current changed attributes.  Called after save.
          def clear_changed_attributes
            self.changed_attributes = []
          end

          def write_changed_attribute(attr_name, attr_value)
            # Convert to db type for comparison. Avoids failing Float<=>String comparisons.
            attr_value_for_db = self.class.columns_hash[attr_name.to_s].type_cast(attr_value)
            (self.changed_attributes ||= []) << attr_name.to_s unless self.changed?(attr_name) || self.send(attr_name) == attr_value_for_db
            write_attribute(attr_name, attr_value_for_db)
          end

        private
          CALLBACKS.each do |attr_name| 
            alias_method "orig_#{attr_name}".to_sym, attr_name
          end

        module ClassMethods
          # Finds a specific version of a specific row of this model
          def find_version(id, version)
            find_versions(id, 
              :conditions => ["#{versioned_foreign_key} = ? AND version = ?", id, version], 
              :limit => 1).first
          end
        
          # Finds versions of a specific model.  Takes an options hash like <tt>find</tt>
          def find_versions(id, options = {})
            versioned_class.find :all, {
              :conditions => ["#{versioned_foreign_key} = ?", id],
              :order      => 'version' }.merge(options)
          end

          # Returns an array of columns that are versioned.  See non_versioned_columns
          def versioned_columns
            self.columns.select { |c| !non_versioned_columns.include?(c.name) }
          end
    
          # Returns an instance of the dynamic versioned model
          def versioned_class
            const_get versioned_class_name
          end

          # Rake migration task to create the versioned table using options passed to acts_as_versioned
          def create_versioned_table(create_table_options = {})
            # create version column in main table if it does not exist
            if !self.content_columns.find { |c| %w(version lock_version).include? c.name }
              self.connection.add_column table_name, :version, :integer
            end
            
            self.connection.create_table(versioned_table_name, create_table_options) do |t|
              t.column versioned_foreign_key, :integer
              t.column :version, :integer
            end
            
            updated_col = nil
            self.versioned_columns.each do |col| 
              updated_col = col if !updated_col && %(updated_at updated_on).include?(col.name)
              self.connection.add_column versioned_table_name, col.name, col.type, 
                :limit => col.limit, 
                :default => col.default
            end
        
            if type_col = self.columns_hash[inheritance_column]
              self.connection.add_column versioned_table_name, versioned_inheritance_column, type_col.type, 
                :limit => type_col.limit, 
                :default => type_col.default
            end
    
            if updated_col.nil?
              self.connection.add_column versioned_table_name, :updated_at, :timestamp
            end
          end
          
          # Rake migration task to drop the versioned table
          def drop_versioned_table
            self.connection.drop_table versioned_table_name
          end
          
          # Executes the block with the versioning callbacks disabled.
          #
          #   Foo.without_revision do
          #     @foo.save
          #   end
          #
          def without_revision(&block)
            class_eval do 
              CALLBACKS.each do |attr_name| 
                alias_method attr_name, :empty_callback
              end
            end
            result = block.call
            class_eval do 
              CALLBACKS.each do |attr_name|
                alias_method attr_name, "orig_#{attr_name}".to_sym
              end
            end
            result
          end

          # Turns off optimistic locking for the duration of the block
          #
          #   Foo.without_locking do
          #     @foo.save
          #   end
          #
          def without_locking(&block)
            current = ActiveRecord::Base.lock_optimistically
            ActiveRecord::Base.lock_optimistically = false if current
            result = block.call
            ActiveRecord::Base.lock_optimistically = true if current
            result
          end          
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::Acts::Versioned