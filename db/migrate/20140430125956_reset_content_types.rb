class ResetContentTypes < ActiveRecord::Migration
  def up
    Attachment.all.each do |attachment|
      attachment.update_column(:content_type, Attachment.content_type_for(attachment.diskfile))
    end
  end

  def down
    # noop
  end
end
