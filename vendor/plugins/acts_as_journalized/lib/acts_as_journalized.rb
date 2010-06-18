module Redmine
  module Acts
    module Journalized
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_journalized(options = {})
          return if self.included_modules.include?(Redmine::Acts::Journalized::InstanceMethods)
          
          self.include Redmine::Acts::Journalized::InstanceMethods
          
          plural_name = self.name.underscore.pluralize
          journal_name = "#{self.name}Journal"
          
          extra_module = options.delete(:extra_module)

          event_hash = {
            :description => :notes,
            :author => Proc.new {|o| User.find_by_id(o.journal.user_id)},
            :url => Proc.new do |o|
              {
                :controller => self.name.underscore.pluralize,
                :action => 'show',
                :id => o.id,
                :anchor => "change-#{o.id}"
              }
            end
          }
          
          activity_hash = {
            :type => plural_name,
            :permission => "view_#{plural_name}".to_sym,
            :author_key => :user_id,
          }
          
          options.each_pair do |k, v|
            case
            when key = k.to_s.slice(/event_(.+)/, 1)
              event_hash[key.to_sym] = v
            when key = k.to_s.slice(/activity_(.+)/, 1)
              activity_hash[key.to_sym] = v
            end
          end

          # create the new model class
          journal = Class.new(Journal)
          journal.belongs_to self.name.underscore
          journal.acts_as_event event_hash
          journal.acts_as_activity_provider activity_hash
          journal.send(:include, extra_module)
          Object.const_set("#{self.name}Journal", journal)
          
          unless Redmine::Activity.providers[plural_name].include? self.name
            Redmine::Activity.register plural_name.to_sym
          end
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
          
          base.class_eval do
            after_save :create_journal
            has_many :journals, :class_name => "#{self.name}Journal", :dependent => :destroy
          end
        end
        
        def journal_class
          "#{self.class.name}Journal".constantize
        end
        
        def init_journal(user, notes = "")
          @notes ||= ""
          @current_journal ||= journal_class.new(:journalized => self, :user => user, :notes => notes)
          @object_before_change = self.clone
          @object_before_change.status = self.status
          if self.respond_to? :custom_values
            @custom_values_before_change = {}
            self.custom_values.each {|c| @custom_values_before_change[c.custom_field_id] = c.value }
          end
          # Make sure updated_on is updated when adding a note.
          updated_on_will_change!
          @current_journal
        end
        
        # Saves the changes in a Journal
        # Called after_save
        def create_journal
          if @current_journal
            details = {:attr => {}}
            if self.respond_to? :custom_values
              details[:cf] = {}
            end

            # attributes changes
            self.class.journalized_columns.each do |c|
              unless send(c) == @object_before_change.send(c)
                details[:attr][c] = {
                  :old => @object_before_change.send(c),
                  :new => send(c)
                }
              end
            end
            
            if self.respond_to? :custom_values
              # custom fields changes
              custom_values.each do |c|
                unless ( @custom_values_before_change[c.custom_field_id]==c.value ||
                        (@custom_values_before_change[c.custom_field_id].blank? && c.value.blank?))
                  details[:cf][c.custom_field_id] = {
                    :old => @custom_values_before_change[c.custom_field_id],
                    :new => c.value
                  }
                end
              end
            end
            @current_journal.details = details
            @current_journal.save
          end
        end
        
        module ClassMethods
          def journalized_columns=(columns = [])
            @journalized_columns = columns
          end
          
          def journalized_columns
            @journalized_columns ||= begin
              (self.column_names - %w(id description lock_version created_on updated_on))
            end
          end
        end
      end
    end
  end
end
