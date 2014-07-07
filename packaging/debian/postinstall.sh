#!/usr/bin/env bash

# run migrations and seed data if possible
openproject run rake db:migrate db:seed || true
service openproject restart || true

