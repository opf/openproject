require 'helper'

class MyMailer < ActionMailer::Base
  def signup(email)
    mail :to => email, :subject => 'Delaying Emails', :from => 'delayedjob@example.com', :body => 'Delaying Emails Body'
  end
end

describe ActionMailer::Base do
  describe 'delay' do
    it 'enqueues a PerformableEmail job' do
      expect do
        job = MyMailer.delay.signup('john@example.com')
        expect(job.payload_object.class).to eq(Delayed::PerformableMailer)
        expect(job.payload_object.method_name).to eq(:signup)
        expect(job.payload_object.args).to eq(['john@example.com'])
      end.to change { Delayed::Job.count }.by(1)
    end
  end

  describe 'delay on a mail object' do
    it 'raises an exception' do
      expect do
        MyMailer.signup('john@example.com').delay
      end.to raise_error(RuntimeError)
    end
  end

  describe Delayed::PerformableMailer do
    describe 'perform' do
      it 'calls the method and #deliver on the mailer' do
        email = double('email', :deliver => true)
        mailer_class = double('MailerClass', :signup => email)
        mailer = Delayed::PerformableMailer.new(mailer_class, :signup, ['john@example.com'])

        expect(mailer_class).to receive(:signup).with('john@example.com')
        expect(email).to receive(:deliver)
        mailer.perform
      end
    end
  end
end
