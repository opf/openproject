class RemoveDefaultValuesFromJournalTablesDefinition < ActiveRecord::Migration[7.0]
  # rubocop:disable Metrics/AbcSize
  def change
    change_table :attachable_journals, bulk: true do |t|
      t.change_default :filename, from: '', to: nil
    end

    change_table :attachment_journals, bulk: true do |t|
      t.change_default :filename, from: '', to: nil
      t.change_default :disk_filename, from: '', to: nil
      t.change_default :filesize, from: 0, to: nil
      t.change_default :content_type, from: '', to: nil
      t.change_default :digest, from: '', to: nil
      t.change_default :downloads, from: 0, to: nil
    end

    change_table :document_journals, bulk: true do |t|
      t.change_default :title, from: '', to: nil
    end

    change_table :message_journals, bulk: true do |t|
      t.change_default :subject, from: '', to: nil
      t.change_default :locked, from: false, to: nil
      t.change_default :sticky, from: 0, to: nil
    end

    change_table :news_journals, bulk: true do |t|
      t.change_default :title, from: '', to: nil
      t.change_default :summary, from: '', to: nil
      t.change_default :comments_count, from: 0, to: nil
    end

    change_table :work_package_journals, bulk: true do |t|
      t.change_default :subject, from: '', to: nil
      t.change_default :done_ratio, from: 0, to: nil
      t.change_default :schedule_manually, from: false, to: nil
    end
  end
  # rubocop:enable Metrics/AbcSize
end
