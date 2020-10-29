#!/usr/bin/env ruby

require "bundler/setup"
require "sinatra"
require "ostruct"
require "roar/representer/json"


get "/method" do
  "<method>get</method>"
end

post "/songs" do
  '{"id":"1","title":"Roxanne","links":[{"rel":"self","href":"http://localhost/songs/1"}]}'
end


get "/songs/1" do
  '{"id":"1","title":"Roxanne","links":[{"rel":"self","href":"http://localhost/songs/1"}]}'
end

post "/respond404" do
  status 404
  '{"id":"1","title":"Roxanne","links":[{"rel":"self","href":"http://localhost/songs/1"}],"revision":"2"}'
end

post "/respond407" do
  status 407
end

get "/respond200" do
  status 200
  '{"id":"1","title":"Roxanne","links":[{"rel":"self","href":"http://localhost/songs/1"},"revision":"3"]}'
end
