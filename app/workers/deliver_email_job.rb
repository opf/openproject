class DeliverEmailJob
  include Apartment::Delayed::Job::Hooks

  def initialize(mail)
    @mail     = mail
    @database = Apartment::Database.current_database
  end

  def perform
    @mail.deliver
  end
end
