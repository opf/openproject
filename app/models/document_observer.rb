class DocumentObserver < ActiveRecord::Observer
  def after_create(document)
    Mailer.deliver_document_added(document) if Setting.notified_events.include?('document_added')
  end
end
