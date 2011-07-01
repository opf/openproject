class BuildInitialJournalsForActsAsJournalized < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the JournalDetails has been removed
    unless Object.const_defined?("JournalDetails")
      Object.const_set("JournalDetails", Class.new(ActiveRecord::Base))
    end

    # Reset class and subclasses, otherwise they will try to save using older attributes
    Journal.reset_column_information
    Journal.send(:subclasses).each do |klass|
      klass.reset_column_information if klass.respond_to?(:reset_column_information)
    end

    providers = Redmine::Activity.providers.collect {|k, v| v.collect(&:constantize) }.flatten.compact.uniq
    providers.each do |p|
      next unless p.table_exists? # Objects not in the DB yet need creation journal entries

      say_with_time("Building initial journals for #{p.class_name}") do

        activity_type = p.activity_provider_options.keys.first

        p.find(:all).each do |o|
          # Create initial journals
          new_journal = o.journals.build
          # Mock up a list of changes for the creation journal based on Class defaults
          new_attributes = o.class.new.attributes.except(o.class.primary_key,
                                                         o.class.inheritance_column,
                                                         :updated_on,
                                                         :updated_at,
                                                         :lock_version,
                                                         :lft,
                                                         :rgt)
          creation_changes = {}
          new_attributes.each do |name, default_value|
            # Set changes based on the initial value to current. Can't get creation value without
            # rebuiling the object history
            creation_changes[name] = [default_value, o.send(name)] # [initial_value, creation_value]
          end
          new_journal.changes = creation_changes
          new_journal.version = 1
          new_journal.activity_type = activity_type
          
          if o.respond_to?(:author)
            new_journal.user = o.author
          elsif o.respond_to?(:user)
            new_journal.user = o.user
          end
          # Using rescue and save! here because either the Journal or the
          # touched record could fail. This will catch either error and continue
          begin
            new_journal.save!
            
            new_journal.reload
          
            # Backdate journal
            if o.respond_to?(:created_at)
              new_journal.update_attribute(:created_at, o.created_at)
            elsif o.respond_to?(:created_on)
              new_journal.update_attribute(:created_at, o.created_on)
            end
          rescue ActiveRecord::RecordInvalid => ex
            if new_journal.errors.count == 1 && new_journal.errors.first[0] == "version"
              # Skip, only error was from creating the initial journal for a record that already had one.
            else
              puts "ERROR: errors creating the initial journal for #{o.class.to_s}##{o.id.to_s}:"
              puts "  #{ex.message}"
            end
          end
        end
        
      end
    end
    
  end

  def self.down
    # No-op
  end
    
end
