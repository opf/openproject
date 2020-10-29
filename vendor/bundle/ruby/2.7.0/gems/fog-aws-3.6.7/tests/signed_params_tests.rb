# encoding: utf-8

Shindo.tests('AWS | signed_params', ['aws']) do
  returns(Fog::AWS.escape("'Stöp!' said Fred_-~./")) { '%27St%C3%B6p%21%27%20said%20Fred_-~.%2F' }

  tests('Unicode characters should be escaped') do
    unicode = ['00E9'.to_i(16)].pack('U*')
    escaped = '%C3%A9'
    returns(escaped) { Fog::AWS.escape(unicode) }
  end

  tests('Unicode characters with combining marks should be escaped') do
    unicode = ['0065'.to_i(16), '0301'.to_i(16)].pack('U*')
    escaped = 'e%CC%81'
    returns(escaped) { Fog::AWS.escape(unicode) }
  end
end
