require File.expand_path('../../test_helper', __FILE__)

class UserMailerTest < ActionMailer::TestCase
  #include Redmine::I18n
  
  setup do
    User.delete_all
    Issue.delete_all
    Project.delete_all
    Tracker.delete_all        
    ActionMailer::Base.deliveries.clear
  end
  
  test 'test email sends a simple greeting to the given user' do
    user = FactoryGirl.create(:user, :mail => 'foo@bar.de', :language => :de)
    
    mail = UserMailer.test_mail(user)
    mail.deliver

    assert_equal 1, ActionMailer::Base.deliveries.size
    
    assert_equal "Test", mail.subject
    assert_equal ['foo@bar.de'], mail.to
    assert_equal ['from@example.com'], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "issue added" do
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)

    # creating an issue actually sends an email, wow
    ActionMailer::Base.deliveries.clear
        
    mail = UserMailer.issue_added(user, issue)
    mail.deliver
  
    assert_equal 1, ActionMailer::Base.deliveries.size
  
    # todo
    # assert_equal "Test", mail.subject
    # assert_equal ['foo@bar.de'], mail.to
    # assert_equal ['from@example.com'], mail.from
    # assert_match "Hi", mail.body.encoded    
  end
  
  test 'test_email_headers' do
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)
    
    mail = UserMailer.issue_added(user, issue)
    mail.deliver
    
    assert_not_nil mail
    assert_equal 'bulk', mail.header_string('Precedence')
    assert_equal 'auto-generated', mail.header_string('Auto-Submitted')
  end

  test 'test_issue_add_message_id' do
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)

    mail = UserMailer.issue_added(user, issue)
    mail.deliver
    
    assert_not_nil mail
    assert_equal UserMailer.message_id_for(issue), mail.message_id
    assert_nil mail.references
  end
  
  test 'test_issue_add' do
    user  = FactoryGirl.create(:user)
    issue = FactoryGirl.create(:issue)

    assert UserMailer.issue_added(user, issue).deliver
  end
  
  test 'test_issue_edit' do
    user  = FactoryGirl.create(:user)  
    journal = Journal.find(1)
    assert UserMailer.issue_updated(user, journal).deliver
  end
  
  def test_password_lost
    token = FactoryGirl.create(:token)
    assert UserMailer.password_lost(token).deliver
  end
  
  
  
  context("#issue_add") do
    setup do
      ActionMailer::Base.deliveries.clear
      Setting.bcc_recipients = '1'
      @user = FactoryGirl.create(:user, :mail => 'foo@bar.de')
      @issue = FactoryGirl.create(:issue)
    end
  
    should "send one email per recipient" do
      assert UserMailer.issue_added(@user, @issue).deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_equal ['foo@bar.de'], last_email.to
    end
  
    should "change mail language depending on recipient language" do
      Setting.stubs(:available_languages).returns(['en', 'de'])
      set_language_if_valid 'en'
  
      @user.language = 'de'
  
      assert UserMailer.issue_added(@user, @issue).deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
  
      mail = last_email
      assert_equal ['foo@bar.de'], mail.to
      assert mail.body.include?('erstellt')
      assert !mail.body.include?('reported')
      assert_equal :en, current_language
    end
  
    should "falls back to default language if user has no language" do
      # 1. user's language
      # 2. Setting.default_language
      # 3. :en
  
      Setting.stubs(:available_languages).returns(['en', 'de', 'fr'])
      set_language_if_valid 'fr'
  
      Setting.default_language = 'de'
  
      @user.language = '' # (auto)
  
      assert UserMailer.issue_added(@user, @issue).deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
  
      mail = last_email
      assert_equal ['foo@bar.de'], mail.to
      assert !mail.body.include?('reported')
      assert mail.body.include?('erstellt')
      assert_equal :fr, current_language
    end
  end

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

  def test_news_added
    news = News.find(:first)
    assert UserMailer.news_added(@user, news).deliver
  end

  def test_should_not_send_email_without_recipient
    news = News.find(:first)
    user = news.author
    # Remove members except news author
    news.project.memberships.each {|m| m.destroy unless m.user == user}

    user.pref[:no_self_notified] = false
    user.pref.save
    User.current = user
    UserMailer.news_added(user, news.reload).deliver
    assert_equal 1, last_email.to.size

    # nobody to notify
    user.pref[:no_self_notified] = true
    user.pref.save
    User.current = user
    ActionMailer::Base.deliveries.clear
    UserMailer.news_added(user, news.reload).deliver
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_user_signed_up
    token = Token.find(1)
    Setting.host_name = 'redmine.foo'
    Setting.protocol = 'https'

    ActionMailer::Base.deliveries.clear
    assert UserMailer.user_signed_up(token).deliver
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?("https://redmine.foo/account/activate?token=#{token.value}")
  end

  def test_news_comment_added
    user    = FactoryGirl.create(:user)
    comment = Comment.find(2)
    assert UserMailer.news_comment_added(user, comment).deliver
  end

  def test_wiki_content_added
    user    = FactoryGirl.create(:user)
    content = WikiContent.find(1)
    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert UserMailer.wiki_content_added(user, content).deliver
    end
  end

  def test_wiki_content_updated
    user    = FactoryGirl.create(:user)
    content = WikiContent.find(1)
    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert UserMailer.wiki_content_updated(user, content).deliver
    end
  end

  def test_message_posted_message_id
    user    = FactoryGirl.create(:user)
    message = Message.find(1)
    UserMailer.message_posted(user, message).deliver
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal Mailer.message_id_for(message), mail.message_id
    assert_nil mail.references
    assert_select_email do
      # link to the message
      assert_select "a[href*=?]", "#{Setting.protocol}://#{Setting.host_name}/boards/#{message.board.id}/topics/#{message.id}", :text => message.subject
    end
  end

  def test_reply_posted_message_id
    user    = FactoryGirl.create(:user)
    message = Message.find(3)
    UserMailer.message_posted(user, message).deliver
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal Mailer.message_id_for(message), mail.message_id
    assert_equal Mailer.message_id_for(message.parent), mail.references.first.to_s
    assert_select_email do
      # link to the reply
      assert_select "a[href=?]", "#{Setting.protocol}://#{Setting.host_name}/boards/#{message.board.id}/topics/#{message.root.id}?r=#{message.id}#message-#{message.id}", :text => message.subject
    end
  end

  def test_message_posted
    user    = FactoryGirl.create(:user)
    message = Message.find(:first)
    assert UserMailer.message_posted(user, message).deliver
  end

  def test_document_added
    user     = FactoryGirl.create(:user)
    document = Document.find(1)
    assert UserMailer.document_added(user, document).deliver
  end

  def test_mailer_should_not_change_locale
    Setting.stubs(:available_languages).returns(['en', 'it', 'fr'])
    Setting.default_language = 'en'
    # Set current language to italian
    set_language_if_valid 'it'
    # Send an email to a french user
    user = FactoryGirl.create(:user)
    user.language = 'fr'
    UserMailer.account_activated(user).deliver
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?('Votre compte')
    assert_equal :it, current_language
  end

  def test_account_information
    user = FactoryGirl.create(:user)
    assert UserMailer.account_information(user, 'pAsswORd').deliver
  end

  def test_account_activation_requested
    admin = FactoryGirl.create(:user)
    user  = FactoryGirl.create(:user)
    assert UserMailer.account_activation_requested(admin, user).deliver
  end
end
