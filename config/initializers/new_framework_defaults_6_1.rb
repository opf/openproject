# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 6.1 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.

# https://guides.rubyonrails.org/configuring.html#config-active-record-has-many-inversing
# Support for inversing belongs_to -> has_many Active Record associations.
# Previous versions had false. Rails 6.1+ default is true.
# Rails.application.config.active_record.has_many_inversing = true

# https://guides.rubyonrails.org/configuring.html#config-active-storage-track-variants
# Track Active Storage variants in the database.
# Previous versions had false. Rails 6.1+ default is true.
# Rails.application.config.active_storage.track_variants = true

# https://guides.rubyonrails.org/configuring.html#config-active-job-retry-jitter
# Apply random variation to the delay when retrying failed jobs.
# Previous versions had 0.0. Rails 6.1+ default is 0.15.
# Rails.application.config.active_job.retry_jitter = 0.15

# Stop executing `after_enqueue`/`after_perform` callbacks if
# `before_enqueue`/`before_perform` respectively halts with `throw :abort`.
# Rails.application.config.active_job.skip_after_callbacks_if_terminated = true

# https://guides.rubyonrails.org/configuring.html#config-action-dispatch-cookies-same-site-protection
# Specify cookies SameSite protection level: either :none, :lax, or :strict.
#
# This change is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.1.
# Previous versions had nil. Rails 6.1+ default is :lax.
# Rails.application.config.action_dispatch.cookies_same_site_protection = :lax

# https://guides.rubyonrails.org/configuring.html#config-action-controller-urlsafe-csrf-tokens
# Generate CSRF tokens that are encoded in URL-safe Base64.
#
# This change is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.1.
# Previous versions had false. Rails 6.1+ default is true.
# Rails.application.config.action_controller.urlsafe_csrf_tokens = true

# https://guides.rubyonrails.org/configuring.html#activesupport-utc-to-local-returns-utc-offset-times
# Specify whether `ActiveSupport::TimeZone.utc_to_local` returns a time with an
# UTC offset or a UTC time.
# Previous versions had false. Rails 6.1+ default is true.
# ActiveSupport.utc_to_local_returns_utc_offset_times = true

# https://guides.rubyonrails.org/configuring.html#config-action-dispatch-ssl-default-redirect-status
# Change the default HTTP status code to `308` when redirecting non-GET/HEAD
# requests to HTTPS in `ActionDispatch::SSL` middleware.
# Previous versions used 307. Rails 6.1+ default is 308.
# Rails.application.config.action_dispatch.ssl_default_redirect_status = 308

# https://guides.rubyonrails.org/configuring.html#config-action-view-form-with-generates-remote-forms
# Make `form_with` generate non-remote forms by default.
# Rails 5.1 to 6.0 default was true. Rails 6.1+ default is false.
# Rails.application.config.action_view.form_with_generates_remote_forms = false

# https://guides.rubyonrails.org/configuring.html#config-active-storage-queues-analysis
# Set the default queue name for the analysis job to the queue adapter default.
# Rails 6.0 used :active_storage_analysis.
# Rails 6.1+ default is nil (when nil, default Active Job queue is used).
# Rails.application.config.active_storage.queues.analysis = nil

# https://guides.rubyonrails.org/configuring.html#config-active-storage-queues-purge
# Set the default queue name for the purge job to the queue adapter default.
# Rails 6.0 used :active_storage_purge.
# Rails 6.1+ default is nil (when nil, default Active Job queue is used).
# Rails.application.config.active_storage.queues.purge = nil

# https://guides.rubyonrails.org/configuring.html#config-action-mailbox-queues-incineration
# Set the default queue name for the incineration job to the queue adapter default.
# Previous versions used :action_mailbox_incineration.
# Rails 6.1+ default is nil (when nil, default Active Job queue is used).
# Rails.application.config.action_mailbox.queues.incineration = nil

# https://guides.rubyonrails.org/configuring.html#config-action-mailbox-queues-routing
# Set the default queue name for the routing job to the queue adapter default.
# Previous versions used :action_mailbox_routing.
# Rails 6.1+ default is nil (when nil, default Active Job queue is used).
# Rails.application.config.action_mailbox.queues.routing = nil

# https://guides.rubyonrails.org/configuring.html#config-action-mailer-deliver-later-queue-name
# Set the default queue name for the mail deliver job to the queue adapter default.
# Previous versions used :mailers.
# Rails 6.1+ default is nil (when nil, default Active Job queue is used).
# Rails.application.config.action_mailer.deliver_later_queue_name = nil

# https://guides.rubyonrails.org/configuring.html#config-action-view-preload-links-header
# Generate a `Link` header that gives a hint to modern browsers about
# preloading assets when using `javascript_include_tag` and `stylesheet_link_tag`.
# Previous versions had false. Rails 6.1+ default is true.
# Rails.application.config.action_view.preload_links_header = true
