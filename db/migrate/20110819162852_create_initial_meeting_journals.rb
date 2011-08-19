class CreateInitialMeetingJournals < ActiveRecord::Migration
  def self.up

    [Meeting].each do |p|
      say_with_time("Building initial journals for #{p.class_name}") do
    
        # avoid touching the journaled object on journal creation
        p.journal_class.class_exec {
          def touch_journaled_after_creation
          end
        }
    
        activity_type = p.activity_provider_options.keys.first
    
        # Create initial journals
        p.find(:all).each do |o|
          # Using rescue and save! here because either the Journal or the
          # touched record could fail. This will catch either error and continue
          begin
            new_journal = o.recreate_initial_journal!
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
    # no-op
    # (well, in theory we should delete the MeetingJournals…)
  end
end
