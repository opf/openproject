class UpdateJournalsForActsAsJournalized < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the JournalDetails has been removed
    unless Object.const_defined?("JournalDetails")
      Object.const_set("JournalDetails", Class.new(ActiveRecord::Base))
    end

    say_with_time("Updating existing Journals...") do
      Journal.all.group_by(&:journaled_id).each_pair do |id, journals|
        journals.sort_by(&:created_at).each_with_index do |j, idx|
          # Recast the basic Journal into it's STI journalized class so callbacks work (#467)
          klass_name = "#{j.journalized_type}Journal"
          j = j.becomes(klass_name.constantize)
          j.type = klass_name
          j.version = idx + 1
          # FIXME: Find some way to choose the right activity here
          j.activity_type = j.journalized_type.constantize.activity_provider_options.keys.first
          j.save(false)
        end
      end
    end

    change_table :journals do |t|
      t.remove :journalized_type
    end
  end

  def self.down
    change_table "journals" do |t|
      t.string :journalized_type, :limit => 30, :default => "", :null => false
    end

    custom_field_names = CustomField.all.group_by(&:type)[IssueCustomField].collect(&:name)
    Journal.all.each do |j|
      # Can't used j.journalized.class.name because the model changes make it nil
      j.update_attribute(:journalized_type, j.type.to_s.sub("Journal","")) if j.type.present?
    end

  end
end

