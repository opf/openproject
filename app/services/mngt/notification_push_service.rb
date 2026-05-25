# frozen_string_literal: true

class Mngt::NotificationPushService
  REASON_TITLES = {
    "mentioned"             => "Você foi mencionado",
    "assigned"              => "Tarefa atribuída a você",
    "responsible"           => "Você é responsável",
    "watched"               => "Atualização em tarefa observada",
    "subscribed"            => "Atualização em tarefa inscrita",
    "commented"             => "Novo comentário",
    "created"               => "Nova tarefa criada",
    "processed"             => "Tarefa atualizada",
    "prioritized"           => "Prioridade alterada",
    "scheduled"             => "Prazo alterado",
    "date_alert_start_date" => "Alerta: data de início",
    "date_alert_due_date"   => "Alerta: prazo",
    "shared"                => "Tarefa compartilhada",
    "reminder"              => "Lembrete"
  }.freeze

  def self.call(notification_id)
    notification = Notification.includes(:recipient, :actor, :resource).find_by(id: notification_id)
    return unless notification

    recipient = notification.recipient
    return unless recipient.is_a?(User)

    title  = REASON_TITLES[notification.reason] || "Nova notificação"
    actor  = notification.actor
    body   = build_body(notification, actor)
    url    = build_url(notification)
    icon   = actor_avatar_url(actor)

    Mngt::WebPushService.notify_user(recipient, title:, body:, url:, icon:)
  end

  def self.build_body(notification, actor)
    subject = notification.subject.presence || notification.resource&.to_s
    actor_name = actor&.name.presence

    if actor_name && subject
      "#{actor_name}: #{subject}".truncate(120)
    elsif subject
      subject.truncate(120)
    else
      ""
    end
  end

  def self.build_url(notification)
    resource = notification.resource
    return "/notifications" unless resource

    case resource
    when WorkPackage
      "/work_packages/#{resource.id}"
    else
      "/notifications"
    end
  end

  def self.actor_avatar_url(actor)
    return nil unless actor.is_a?(User)

    path = "/api/v3/users/#{actor.id}/avatar"
    "#{Setting.protocol}://#{Setting.host_name}#{path}"
  end
  private_class_method :build_body, :build_url, :actor_avatar_url
end
