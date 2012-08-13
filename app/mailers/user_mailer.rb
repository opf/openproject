class UserMailer < ActionMailer::Base
  helper :application # textilizable
  
  default :from => "from@example.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.test_mail.subject
  #
  def test_mail(user)
    @greeting = "Hi"

    to = "#{user.name} <#{user.mail}>"
    
    mail :to => to, :subject => 'Test'
  end
  
  def issue_added(user, issue)  
    @issue = issue
    @user  = user
    
    headers["X-OpenProject-Project"] = issue.project.identifier
    headers["X-OpenProject-Issue-Id"] = issue.id
    headers["X-OpenProject-Issue-Author"] = issue.author.login
    headers["X-OpenProject-Type"] = 'Issue'

    assigned_to_header issue.assigned_to
    
    #message_id issue

    to      = user.mail

    locale = user.language.presence || I18n.default_locale # || Setting.default_language

    I18n.with_locale(locale) do
      subject = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"

      mail :to => to, :subject => subject
    end
  end
  
  def issue_updated(user, journal)
    @user    = user
    @journal = journal
    @issue   = journal.journaled.reload
    
    headers["X-OpenProject-Project"] = @issue.project.identifier
    headers["X-OpenProject-Issue-Id"] = @issue.id
    headers["X-OpenProject-Issue-Author"] = @issue.author.login
    headers["X-OpenProject-Type"] = 'Issue'

    assigned_to_header @issue.assigned_to
    
    to = user.mail

    #message_id journal
    #references issue
    #@author = journal.user

    locale = user.language.presence || I18n.default_locale

    I18n.with_locale(locale) do
      subject =  "[#{@issue.project.name} - #{@issue.tracker.name} ##{@issue.id}] "
      subject << "(#{@issue.status.name}) " if journal.details['status_id']
      subject << @issue.subject

      mail :to => to, :subject => subject
    end
  end
  
  def password_lost(token)
    @token = token
    @reset_password_url = url_for(:controller => :account,
                                  :action     => :lost_password,
                                  :token      => @token.value)
    
    headers["X-OpenProject-Type"] = 'Account'
    
    user = token.user

    to = user.mail

    locale = user.language.presence || I18n.default_locale  

    I18n.with_locale(locale) do
      subject = t(:mail_subject_lost_password, :value => Setting.app_title)      

      mail :to => to, :subject => subject
    end
  end

  def news_added(user, news)
    @news = news

    headers["X-OpenProject-Project"] = news.project.identifier
    headers["X-OpenProject-Type"] = "News"

    #message_id news

    to = user.mail

    locale = user.language.presence || I18n.default_locale

    I18n.with_locale(locale) do
      subject = "[#{news.project.name}] #{t(:label_news)}: #{news.title}"

      mail :to => to, :subject => subject
    end
  end

  def user_signed_up(token)
    @token = token
    @activation_url = url_for(:controller => :account,
                              :action     => :activate,
                              :token      => @token.value)

    headers["X-OpenProject-Type"] = "Account"

    user = token.user

    to = user.mail

    locale = user.language.presence || I18n.default_locale

    I18n.with_locale(locale) do
      subject = t(:mail_subject_register, :value => Setting.app_title)

      mail :to => to, :subject => subject
    end
  end

  def news_comment_added(user, comment)
    @comment = comment
    @news = @comment.commented

    headers["X-OpenProject-Project"] = @news.project.identifier

    #message_id comment
    to = user.mail

    I18n.with_locale(locale) do
      subject = "Re: [#{@news.project.name}] #{t(:label_news)}: #{@news.title}"

      mail :to => to, :subject => subject
    end
  end

  def wiki_content_added(user, wiki_content)
    @wiki_content = wiki_content

    headers["X-OpenProject-Project"] = @wiki_content.project.identifier
    headers["X-OpenProject-Wiki-Page-Id"] = @wiki_content.page.id
    headers["X-OpenProject-Type"] = "Wiki"

    # message_id wiki_content
    to = user.mail

    I18n.with_locale(locale) do
      subject = "[#{wiki_content.project.name}] #{t(:mail_subject_wiki_content_added, :id => wiki_content.page.pretty_title)}"

      mail :to => to, :subject => subject
    end
  end

  def wiki_content_updated(user, wiki_content)
    @wiki_content  = wiki_content
    @wiki_diff_url = url_for(:controller => :wiki,
                             :action     => :diff,
                             :project_id => wiki_content.project,
                             :id         => wiki_content.page.title,
                             :version    => wiki_content.version)

    headers["X-OpenProject-Project"] = @wiki_content.project.identifier
    headers["X-OpenProject-Wiki-Page-Id"] = @wiki_content.page.id
    headers["X-OpenProject-Type"] = "Wiki"

    #message_id wiki_content
    to = user.mail

    I18n.with_locale(locale) do
      subject = "[#{wiki_content.project.name}] #{t(:mail_subject_wiki_content_updated, :id => wiki_content.page.pretty_title)}"

      mail :to => to, :subject => subject
    end
  end

private

  def assigned_to_header(user)
    headers["X-OpenProject-Issue-Assignee"] = user.login if user
  end
end
