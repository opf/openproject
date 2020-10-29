# frozen_string_literal: true

require "active_record"
require "delayed_job"
require "delayed/backend/active_record"

Delayed::Worker.backend = :active_record
