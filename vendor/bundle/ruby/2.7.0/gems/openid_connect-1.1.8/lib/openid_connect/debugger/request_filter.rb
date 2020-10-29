module OpenIDConnect
  module Debugger
    class RequestFilter
      # Callback called in HTTPClient (before sending a request)
      # request:: HTTP::Message
      def filter_request(request)
        started = "======= [OpenIDConnect] HTTP REQUEST STARTED ======="
        log started, request.dump
      end

      # Callback called in HTTPClient (after received a response)
      # request::  HTTP::Message
      # response:: HTTP::Message
      def filter_response(request, response)
        finished = "======= [OpenIDConnect] HTTP REQUEST FINISHED ======="
        log '-' * 50, response.dump, finished
      end

      private

      def log(*outputs)
        outputs.each do |output|
          OpenIDConnect.logger.info output
        end
      end
    end
  end
end