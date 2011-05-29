class CommentObserver < ActiveRecord::Observer
  def after_create(comment)
    if comment.commented.is_a?(News) && Setting.notified_events.include?('news_comment_added')
      Mailer.deliver_news_comment_added(comment)
    end
  end
end
