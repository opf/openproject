class FixInvalidJournals < ActiveRecord::Migration[7.0]
  def up
    get_broken_journals.each do |journable_type, relation|
      next unless relation.any?

      # rubocop:disable Rails/Output
      puts "Cleaning up broken journals on #{journable_type}"
      # rubocop:enable Rails/Output
      relation.destroy_all
    end
  end

  def down
    # nothing to do
  end

  def get_broken_journals
    Journal
      .pluck('DISTINCT(journable_type)')
      .compact
      .to_h do |journable_type|
      journal_class = journable_type.constantize.journal_class

      relation = Journal
        .where(journable_type:)
        .where.not(data_type: journal_class.to_s)

      [journable_type, relation]
    end
  end
end
