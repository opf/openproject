# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 6.0 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.

# https://guides.rubyonrails.org/configuring.html#config-action-view-default-enforce-utf8
# Don't force requests from old versions of IE to be UTF-8 encoded.
# Previous versions had true. Rails 6.0+ default is false.
# Rails.application.config.action_view.default_enforce_utf8 = false

# https://guides.rubyonrails.org/configuring.html#config-action-dispatch-use-cookies-with-metadata
# Embed purpose and expiry metadata inside signed and encrypted
# cookies for increased security.
#
# This option is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.0.
# Rails 6.0+ default is true.
# Rails.application.config.action_dispatch.use_cookies_with_metadata = true

# Change the return value of `ActionDispatch::Response#content_type` to Content-Type header without modification.
# Rails.application.config.action_dispatch.return_only_media_type_on_content_type = false

# Return false instead of self when enqueuing is aborted from a callback.
# Rails.application.config.active_job.return_false_on_aborted_enqueue = true

# https://guides.rubyonrails.org/configuring.html#config-active-storage-queues-analysis
# https://guides.rubyonrails.org/configuring.html#config-active-storage-queues-purge
# Send Active Storage analysis and purge jobs to dedicated queues.
#
# Rails 6.0 default is :active_storage_analysis.
# Rails 6.1+ default is nil (when nil, purge jobs are sent to the default
# Active Job queue (see config.active_job.default_queue_name))
# Rails.application.config.active_storage.queues.analysis = :active_storage_analysis
#
# Rails 6.0 default is :active_storage_purge.
# Rails 6.1+ default is nil (when nil, analysis jobs are sent to the default
# Active Job queue (see config.active_job.default_queue_name))
# Rails.application.config.active_storage.queues.purge = :active_storage_purge

# https://guides.rubyonrails.org/configuring.html#config-active-storage-replace-on-assign-to-many
# When assigning to a collection of attachments declared via `has_many_attached`, replace existing
# attachments instead of appending. Use #attach to add new attachments without replacing existing ones.
# Previous versions had false. Rails 6.0+ default is true.
# Rails.application.config.active_storage.replace_on_assign_to_many = true

# https://guides.rubyonrails.org/configuring.html#config-action-mailer-delivery-job
# Use ActionMailer::MailDeliveryJob for sending parameterized and normal mail.
#
# The default delivery jobs (ActionMailer::Parameterized::DeliveryJob, ActionMailer::DeliveryJob),
# will be removed in Rails 6.1. This setting is not backwards compatible with earlier Rails versions.
# If you send mail in the background, job workers need to have a copy of
# MailDeliveryJob to ensure all delivery jobs are processed properly.
# Make sure your entire app is migrated and stable on 6.0 before using this setting.
# Rails.application.config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"

# https://guides.rubyonrails.org/configuring.html#config-active-record-collection-cache-versioning
# Enable the same cache key to be reused when the object being cached of type
# `ActiveRecord::Relation` changes by moving the volatile information (max updated at and count)
# of the relation's cache key into the cache version to support recycling cache key.
# Previous versions had false. Rails 6.0+ default is true.
# Rails.application.config.active_record.collection_cache_versioning = true

# Enable the new autoloader zeitwerk for autoloading and reloading constants
# Rails.application.config.autoloader = :zeitwerk if RUBY_ENGINE == "ruby"
