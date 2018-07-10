#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

##
# We use this extra job instead of just calling
#
# ```
# UserMailer.some_mail("some param").deliver_later
# ```
#
# because we want to have the sending of the email run in an `ApplicationJob`
# as opposed to using `ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper`.
# We want it to run in an `ApplicationJob` because of the shared setup required
# such as reloading the mailer configuration and resetting the request store.
#
# Hence instead of the line above you would deliver an email later like this:
#
# ```
# Delayed::Job.enqueue MailUserJob.new(:some_mail, "some param")
# # or like this:
# MailUserJob.some_mail "some_param"
# ```
class MailUserJob < ApplicationJob
  attr_reader :mail

  def initialize(mail, *args)
    @mail = mail
    @serialized_params = args.map { |arg| serialize_param arg }
  end

  def perform
    UserMailer.send(mail, *params).deliver_now
  end

  def params
    @params ||= @serialized_params.map do |type, param, model_name|
      if type == :model
        deserialize_model param, model_name
      else
        param
      end
    end
  end

  def self.method_missing(method, *args, &block)
    UserMailer.send method unless UserMailer.respond_to? method # fail with NoMethodError

    job = MailUserJob.new method, *args

    Delayed::Job.enqueue job
  end

  private

  def serialize_param(param)
    if param.is_a? ActiveRecord::Base
      [:model, param.id, param.class.name]
    else
      [:plain, param]
    end
  end

  def deserialize_model(id, model_name)
    model_name.constantize.find_by(id: id)
  end
end
