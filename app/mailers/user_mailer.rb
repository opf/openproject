class UserMailer < ActionMailer::Base
  # for textilizable
  helper :application

  # wrap in a lambda to allow changing at run-time
  default :from => lambda { Setting.mail_from }

  def test_mail(user)
    @welcome_url = url_for(:controller => :welcome)
    
    headers['X-OpenProject-Type'] = 'Test'

    with_locale_for(user) do
      mail :to => "#{user.name} <#{user.mail}>", :subject => 'OpenProject Test'
    end
  end

  def issue_added(user, issue)  
    @issue = issue
    
    headers['X-OpenProject-Project'] = @issue.project.identifier
    headers['X-OpenProject-Issue-Id'] = @issue.id
    headers['X-OpenProject-Issue-Author'] = @issue.author.login
    headers['X-OpenProject-Type'] = 'Issue'
    headers['X-OpenProject-Issue-Assignee'] = @issue.assigned_to.login if @issue.assigned_to
    
    #message_id @issue

    with_locale_for(user) do
      subject = "[#{@issue.project.name} - #{@issue.tracker.name} ##{@issue.id}] (#{@issue.status.name}) #{@issue.subject}"
      mail :to => user.mail, :subject => subject
    end
  end
  
  def issue_updated(user, journal)
    @journal = journal
    @issue   = journal.journaled.reload
    
    headers['X-OpenProject-Project'] = @issue.project.identifier
    headers['X-OpenProject-Issue-Id'] = @issue.id
    headers['X-OpenProject-Issue-Author'] = @issue.author.login
    headers['X-OpenProject-Type'] = 'Issue'
    headers['X-OpenProject-Issue-Assignee'] = @issue.assigned_to.login if @issue.assigned_to
    
    #message_id @journal
    #references @issue

    with_locale_for(user) do
      subject =  "[#{@issue.project.name} - #{@issue.tracker.name} ##{@issue.id}] "
      subject << "(#{@issue.status.name}) " if @journal.details['status_id']
      subject << @issue.subject

      mail :to => user.mail, :subject => subject
    end
  end
  
  def password_lost(token)
    @token = token
    @reset_password_url = url_for(:controller => :account,
                                  :action     => :lost_password,
                                  :token      => @token.value)

    headers['X-OpenProject-Type'] = 'Account'

    user = token.user
    with_locale_for(user) do
      subject = t(:mail_subject_lost_password, :value => Setting.app_title)
      mail :to => user.mail, :subject => subject
    end
  end

  def news_added(user, news)
    @news = news

    headers['X-OpenProject-Project'] = @news.project.identifier
    headers['X-OpenProject-Type'] = "News"

    #message_id @news

    with_locale_for(user) do
      subject = "[#{@news.project.name}] #{t(:label_news)}: #{@news.title}"
      mail :to => user.mail, :subject => subject
    end
  end

  def user_signed_up(token)
    @token = token
    @activation_url = url_for(:controller => :account,
                              :action     => :activate,
                              :token      => @token.value)

    headers['X-OpenProject-Type'] = 'Account'

    user = token.user
    with_locale_for(user) do
      subject = t(:mail_subject_register, :value => Setting.app_title)
      mail :to => user.mail, :subject => subject
    end
  end

  def news_comment_added(user, comment)
    @comment = comment
    @news    = @comment.commented

    headers['X-OpenProject-Project'] = @news.project.identifier

    #message_id @comment

    with_locale_for(user) do
      subject = "Re: [#{@news.project.name}] #{t(:label_news)}: #{@news.title}"
      mail :to => user.mail, :subject => subject
    end
  end

  def wiki_content_added(user, wiki_content)
    @wiki_content = wiki_content

    headers['X-OpenProject-Project'] = @wiki_content.project.identifier
    headers['X-OpenProject-Wiki-Page-Id'] = @wiki_content.page.id
    headers['X-OpenProject-Type'] = 'Wiki'

    #message_id @wiki_content

    with_locale_for(user) do
      subject = "[#{@wiki_content.project.name}] #{t(:mail_subject_wiki_content_added, :id => @wiki_content.page.pretty_title)}"
      mail :to => user.mail, :subject => subject
    end
  end

  def wiki_content_updated(user, wiki_content)
    @wiki_content  = wiki_content
    @wiki_diff_url = url_for(:controller => :wiki,
                             :action     => :diff,
                             :project_id => wiki_content.project,
                             :id         => wiki_content.page.title,
                             :version    => wiki_content.version)

    headers['X-OpenProject-Project'] = @wiki_content.project.identifier
    headers['X-OpenProject-Wiki-Page-Id'] = @wiki_content.page.id
    headers['X-OpenProject-Type'] = 'Wiki'

    #message_id @wiki_content

    with_locale_for(user) do
      subject = "[#{@wiki_content.project.name}] #{t(:mail_subject_wiki_content_updated, :id => @wiki_content.page.pretty_title)}"
      mail :to => user.mail, :subject => subject
    end
  end

  def message_posted(user, message)
    @message     = message
    @message_url = url_for(:controller => :messages,
                           :action     => :show,
                           :board_id   => @message.board,
                           :id         => @message.root,
                           :r          => @message,
                           :anchor     => "message-#{@message.id}")

    headers['X-OpenProject-Project'] = @message.project.identifier
    headers['X-OpenProject-Topic-Id'] = @message.parent_id || @message.id
    headers['X-OpenProject-Type'] = 'Forum'

    #message_id @message
    #references @message.parent if @message.parent

    with_locale_for(user) do
      subject = "[#{@message.board.project.name} - #{@message.board.name} - msg#{@message.root.id}] #{@message.subject}"
      mail :to => user.mail, :subject => subject
    end
  end

  def document_added(user, document)
    @document = document

    headers['X-OpenProject-Project'] = @document.project.identifier
    headers['X-OpenProject-Type'] = 'Document'

    with_locale_for(user) do
      subject = "[#{@document.project.name}] #{t(:label_document_new)}: #{@document.title}"
      mail :to => user.mail, :subject => subject
    end
  end

  def account_activated(user)
    @user = user

    headers['X-OpenProject-Type'] = 'Account'

    with_locale_for(user) do
      subject = t(:mail_subject_register, :value => Setting.app_title)
      mail :to => user.mail, :subject => subject
    end
  end

  def account_information(user, password)
    @user     = user
    @password = password

    headers['X-OpenProject-Type'] = 'Account'

    with_locale_for(user) do
      subject = t(:mail_subject_register, :value => Setting.app_title)
      mail :to => user.mail, :subject => subject
    end
  end

  def account_activation_requested(admin, user)
    @user           = user
    @activation_url = url_for(:controller => :users,
                              :action     => :index,
                              :status     => User::STATUS_REGISTERED,
                              :sort_key   => :created_on,
                              :sort_order => :desc)

    headers['X-OpenProject-Type'] = 'Account'

    with_locale_for(admin) do
      subject = t(:mail_subject_account_activation_request, :value => Setting.app_title)
      mail :to => admin.mail, :subject => subject
    end
  end

  def attachments_added(user, attachments)
    @attachments = attachments

    container = attachments.first.container

    headers['X-OpenProject-Project'] = container.project.identifier
    headers['X-OpenProject-Type'] = 'Attachment'

    case container.class.name
    when 'Project'
      @added_to     = "#{t(:label_project)}: #{container}"
      @added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container)
    when 'Version'
      @added_to     = "#{t(:label_version)}: #{container.name}"
      @added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container.project)
    when 'Document'
      @added_to     = "#{t(:label_document)}: #{container.title}"
      @added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
    end

    with_locale_for(user) do
      subject = "[#{container.project.name}] #{t(:label_attachment_new)}"
      mail :to => user.mail, :subject => subject
    end
  end

  def reminder_mail(user, issues, days)
    @issues = issues
    @days   = days

    @assigned_issues_url = url_for(:controller     => :issues,
                                   :action         => :index,
                                   :set_filter     => 1,
                                   :assigned_to_id => user.id,
                                   :sort           => 'due_date:asc')

    headers['X-OpenProject-Type'] = 'Issue'

    with_locale_for(user) do
      subject = t(:mail_subject_reminder, :count => @issues.size, :days => @days)
      mail :to => user.mail, :subject => subject
    end
  end
  
  # Activates/desactivates email deliveries during +block+
  def self.with_deliveries(temporary_state = true, &block)
    old_state = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = temporary_state
    yield
  ensure
    ActionMailer::Base.perform_deliveries = old_state
  end

private

  def with_locale_for(user, &block)
    locale = user.language.presence || Setting.default_language.presence || I18n.default_locale
    I18n.with_locale(locale, &block)
  end
end

class DefaultHeadersInterceptor
  def delivering_email(mail)
    mail.headers(default_headers)
  end

  def default_headers
    {
      'X-Mailer'           => 'OpenProject',
      'X-OpenProject-Host' => Setting.host_name,
      'X-OpenProject-Site' => Setting.app_title,
      'Precedence'         => 'bulk',
      'Auto-Submitted'     => 'auto-generated'
    }
  end
end

UserMailer.register_interceptor(DefaultHeadersInterceptor.new)
