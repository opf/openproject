# frozen_string_literal: true

module Mngt
  class ChatChannel < ApplicationCable::Channel
    def subscribed
      stream_from "mngt_chat"
    end
  end
end
