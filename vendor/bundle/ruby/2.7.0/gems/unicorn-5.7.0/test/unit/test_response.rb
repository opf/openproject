# -*- encoding: binary -*-

# Copyright (c) 2005 Zed A. Shaw
# You can redistribute it and/or modify it under the same terms as Ruby 1.8 or
# the GPLv2+ (GPLv3+ preferred)
#
# Additional work donated by contributors.  See git history
# for more information.

require './test/test_helper'
require 'time'

include Unicorn

class ResponseTest < Test::Unit::TestCase
  include Unicorn::HttpResponse

  def test_httpdate
    before = Time.now.to_i - 1
    str = httpdate
    assert_kind_of(String, str)
    middle = Time.parse(str).to_i
    after = Time.now.to_i
    assert before <= middle
    assert middle <= after
  end

  def test_response_headers
    out = StringIO.new
    http_response_write(out, 200, {"X-Whatever" => "stuff"}, ["cool"])
    assert ! out.closed?

    assert out.length > 0, "output didn't have data"
  end

  # ref: <CAO47=rJa=zRcLn_Xm4v2cHPr6c0UswaFC_omYFEH+baSxHOWKQ@mail.gmail.com>
  def test_response_header_broken_nil
    out = StringIO.new
    http_response_write(out, 200, {"Nil" => nil}, %w(hysterical raisin))
    assert ! out.closed?

    assert_match %r{^Nil: \r\n}sm, out.string, 'nil accepted'
  end

  def test_response_string_status
    out = StringIO.new
    http_response_write(out,'200', {}, [])
    assert ! out.closed?
    assert out.length > 0, "output didn't have data"
  end

  def test_response_200
    io = StringIO.new
    http_response_write(io, 200, {}, [])
    assert ! io.closed?
    assert io.length > 0, "output didn't have data"
  end

  def test_response_with_default_reason
    code = 400
    io = StringIO.new
    http_response_write(io, code, {}, [])
    assert ! io.closed?
    lines = io.string.split(/\r\n/)
    assert_match(/.* Bad Request$/, lines.first,
                 "wrong default reason phrase")
  end

  def test_rack_multivalue_headers
    out = StringIO.new
    http_response_write(out,200, {"X-Whatever" => "stuff\nbleh"}, [])
    assert ! out.closed?
    assert_match(/^X-Whatever: stuff\r\nX-Whatever: bleh\r\n/, out.string)
  end

  # Even though Rack explicitly forbids "Status" in the header hash,
  # some broken clients still rely on it
  def test_status_header_added
    out = StringIO.new
    http_response_write(out,200, {"X-Whatever" => "stuff"}, [])
    assert ! out.closed?
  end

  def test_unknown_status_pass_through
    out = StringIO.new
    http_response_write(out,"666 I AM THE BEAST", {}, [] )
    assert ! out.closed?
    headers = out.string.split(/\r\n\r\n/).first.split(/\r\n/)
    assert %r{\AHTTP/\d\.\d 666 I AM THE BEAST\z}.match(headers[0])
  end

  def test_modified_rack_http_status_codes_late
    r, w = IO.pipe
    pid = fork do
      r.close
      # Users may want to globally override the status text associated
      # with an HTTP status code in their app.
      Rack::Utils::HTTP_STATUS_CODES[200] = "HI"
      http_response_write(w, 200, {}, [])
      w.close
    end
    w.close
    assert_equal "HTTP/1.1 200 HI\r\n", r.gets
    r.read # just drain the pipe
    pid, status = Process.waitpid2(pid)
    assert status.success?, status.inspect
  ensure
    r.close
    w.close unless w.closed?
  end
end
