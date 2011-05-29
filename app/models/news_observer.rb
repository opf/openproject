class NewsObserver < ActiveRecord::Observer
  def after_create(news)
    Mailer.deliver_news_added(news) if Setting.notified_events.include?('news_added')
  end
end
