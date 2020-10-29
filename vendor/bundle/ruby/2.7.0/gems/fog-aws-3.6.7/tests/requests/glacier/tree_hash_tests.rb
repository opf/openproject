Shindo.tests('AWS::Glacier | glacier tree hash calcuation', ['aws']) do

  tests('tree_hash(single part < 1MB)') do
    returns(OpenSSL::Digest::SHA256.hexdigest('')) { Fog::AWS::Glacier::TreeHash.digest('')}
  end

  tests('tree_hash(multibyte characters)') do
    body = ("\xC2\xA1" * 1024*1024)
    body.force_encoding('UTF-8') if body.respond_to? :encoding

    expected = OpenSSL::Digest::SHA256.hexdigest(
                OpenSSL::Digest::SHA256.digest("\xC2\xA1" * 1024*512) + OpenSSL::Digest::SHA256.digest("\xC2\xA1" * 1024*512)
              )
    returns(expected) { Fog::AWS::Glacier::TreeHash.digest(body)}
  end

  tests('tree_hash(power of 2 number of parts)') do
    body = ('x' * 1024*1024) + ('y'*1024*1024) + ('z'*1024*1024) + ('t'*1024*1024)
    expected = OpenSSL::Digest::SHA256.hexdigest(
                 OpenSSL::Digest::SHA256.digest(
                    OpenSSL::Digest::SHA256.digest('x' * 1024*1024) + OpenSSL::Digest::SHA256.digest('y' * 1024*1024)
                 ) +
                 OpenSSL::Digest::SHA256.digest(
                   OpenSSL::Digest::SHA256.digest('z' * 1024*1024) + OpenSSL::Digest::SHA256.digest('t' * 1024*1024)
                 )
               )

    returns(expected) { Fog::AWS::Glacier::TreeHash.digest(body)}
  end

  tests('tree_hash(non power of 2 number of parts)') do
    body = ('x' * 1024*1024) + ('y'*1024*1024) + ('z'*1024*1024)
    expected = OpenSSL::Digest::SHA256.hexdigest(
                 OpenSSL::Digest::SHA256.digest(
                    OpenSSL::Digest::SHA256.digest('x' * 1024*1024) + OpenSSL::Digest::SHA256.digest('y' * 1024*1024)
                 ) +
                 OpenSSL::Digest::SHA256.digest('z' * 1024*1024)
               )

    returns(expected) { Fog::AWS::Glacier::TreeHash.digest(body)}
  end

  tests('multipart') do
    tree_hash = Fog::AWS::Glacier::TreeHash.new
    part = ('x' * 1024*1024) + ('y'*1024*1024)
    returns(Fog::AWS::Glacier::TreeHash.digest(part)) { tree_hash.add_part part }

    tree_hash.add_part('z'* 1024*1024 + 't'*1024*1024)

    expected = OpenSSL::Digest::SHA256.hexdigest(
                 OpenSSL::Digest::SHA256.digest(
                    OpenSSL::Digest::SHA256.digest('x' * 1024*1024) + OpenSSL::Digest::SHA256.digest('y' * 1024*1024)
                 ) +
                 OpenSSL::Digest::SHA256.digest(
                   OpenSSL::Digest::SHA256.digest('z' * 1024*1024) + OpenSSL::Digest::SHA256.digest('t' * 1024*1024)
                 )
               )
    returns(expected) { tree_hash.hexdigest}

  end

  # Aligned is used in general sense of https://en.wikipedia.org/wiki/Data_structure_alignment
  # except we are not dealing with data in memory, but with parts in "virtual" space of whole file.
  # Tests for https://github.com/fog/fog-aws/issues/520 and https://github.com/fog/fog-aws/issues/521
  tests('multipart with unaligned parts') do
    tree_hash = Fog::AWS::Glacier::TreeHash.new
    part = ('x' * 512*1024)
    returns(Fog::AWS::Glacier::TreeHash.digest(part)) { tree_hash.add_part part }

    # At this point, we have 0.5MB in tree_hash. That means that the next part we add will not be aligned,
    # because it will start on 0.5MB which is not 1MB boundary.
    part2 = ('x' * 512*1024) + ('y'*1024*1024) + ('z'* 512*1024)
    returns(Fog::AWS::Glacier::TreeHash.digest(part + part2)) { tree_hash.add_part part2 ; tree_hash.hexdigest }

    # Here we are adding another 1.5MB to tree_hash which has size of 3.5MB. Again, 3.5MB is not on 1MB boundary,
    # so this is another unaligned part. It does test different part of code, though.
    tree_hash.add_part('z'* 512*1024 + 't'*1024*1024)

    expected = OpenSSL::Digest::SHA256.hexdigest(
                 OpenSSL::Digest::SHA256.digest(
                    OpenSSL::Digest::SHA256.digest('x' * 1024*1024) + OpenSSL::Digest::SHA256.digest('y' * 1024*1024)
                 ) +
                 OpenSSL::Digest::SHA256.digest(
                   OpenSSL::Digest::SHA256.digest('z' * 1024*1024) + OpenSSL::Digest::SHA256.digest('t' * 1024*1024)
                 )
               )
    returns(expected) { tree_hash.hexdigest}

  end

end
