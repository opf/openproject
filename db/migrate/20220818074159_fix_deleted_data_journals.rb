class FixDeletedDataJournals < ActiveRecord::Migration[7.0]
  def up
    get_missing_journals.each do |journable_type, relation|
      puts "Cleaning up journals on #{journable_type}"

      relation.find_each { |journal| fix_journal_data(journal) }

      count = relation.count
      raise "There shouldn't be any missing data left for #{journable_type}, but found #{count}" if count > 0
    end
  end

  def down
    # nothing to do
  end

  def fix_journal_data(journal)
    # Best case, no successor
    # restore data from work package itself
    if journal.successor.nil?
      raise "Previous also has data nil" if (journal.previous && journal.previous.data.nil?)
      insert_journal_data(journal, journal.previous, write_message: false)
    elsif predecessor = journal.previous
      # Case 2, we do have a predecessor
      take_over_from_predecessor(journal, predecessor)
    elsif journal.successor
      # Case 3, We are the first, but have a successor
      # Look for data in the successor
      take_over_from_successor(journal, journal.successor)
    else
      raise "This should not happen for #{journal.inspect}"
    end
  end

  def insert_journal_data(journal, predecessor, write_message: false)
    service = Journals::CreateService.new(journal.journable, User.system)
    insert_sql = service.instance_eval { insert_data_sql('placeholder', predecessor) }

    result = Journal.connection.uncached do
      ::Journal
        .connection
        .select_one(insert_sql)
    end

    raise "ID is missing #{result.inspect}" unless result['id']

    if write_message
      update_with_new_data!(journal, result['id'])
    else
      journal.update_column(:data_id, result['id'])
    end
  end

  def get_missing_journals
    Journal
      .pluck('DISTINCT(journable_type)')
      .to_h do |journable_type|
      journal_class = journable_type.constantize.journal_class
      table_name = journal_class.table_name

      relation = Journal
        .joins("LEFT OUTER JOIN #{table_name} ON journals.data_type = '#{journal_class.to_s}' AND #{table_name}.id = journals.data_id")
        .where("#{table_name}.id IS NULL")
        .where(journable_type: journable_type)
        .where.not(data_type: nil) # Ignore special tenants with data_type nil errors
        .order('journals.version ASC')
        .includes(:journable)

      [journable_type, relation]
    end
  end

  def take_over_from_predecessor(journal, predecessor)
    raise "Related journal does not have data, this shouldn't be!" if predecessor.data.nil?

    new_data = predecessor.data.dup
    new_data.save!

    update_with_new_data!(journal, new_data.id)
  end

  def take_over_from_successor(journal, successor)
    # The successor itself may also have its data deleted.
    # in this case, look for the first journal with data, or insert
    new_data =
      if successor.data.nil?
        first_journal_with_data = journal.journable.journals.detect { |j| j.data.present? }
        return insert_journal_data(journal, journal.previous, write_message: true) if first_journal_with_data.nil?

        first_journal_with_data.data.dup
      else
        successor.data.dup
      end

    new_data.save!
    update_with_new_data!(journal, new_data.id)
  end

  def update_with_new_data!(journal, data_id)
    notes = journal.notes || ''
    notes << "\n" unless notes.empty?
    notes << "_(This activity had to be modified by the system and may be missing some changes or contain changes from previous or following activities.)_"

    journal.update_columns(notes:, data_id: data_id)
  end
end
