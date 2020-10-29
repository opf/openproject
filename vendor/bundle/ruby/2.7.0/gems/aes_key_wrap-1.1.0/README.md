[![Build Status](https://travis-ci.org/tomdalling/aes_key_wrap.svg?branch=master)](https://travis-ci.org/tomdalling/aes_key_wrap)
[![Test Coverage](https://codeclimate.com/github/tomdalling/aes_key_wrap/badges/coverage.svg)](https://codeclimate.com/github/tomdalling/aes_key_wrap)

# AESKeyWrap 

A Ruby implementation of AES Key Wrap, a.k.a RFC 3394, a.k.a NIST Key Wrap.

## Usage

To wrap a key, call `AESKeyWrap.wrap` with:

 - The plain text key
 - A key-encrypting key (KEK) 
 - An "initial value" (optional)

```ruby
require 'aes_key_wrap'

plaintext_key = ['00112233445566778899AABBCCDDEEFF'].pack('H*') #binary string
kek =  ['000102030405060708090A0B0C0D0E0F'].pack('H*') # binary string
iv = ['DEADBEEFC0FFEEEE'].pack("H*") # binary string (always 8 bytes)

wrapped_key = AESKeyWrap.wrap(plaintext_key, kek, iv)  # iv is optional
```

To unwrap a key, call `AESKeyWrap.unwrap`:

```ruby
unwrapped = AESKeyWrap.unwrap(wrapped_key, kek, iv)  # iv is optional
```

There also `unwrap!`, which throws an exception if unwrapping fails, instead of
returning nil.

## Contributing

Make sure it's got tests, then do the usual fork and pull request hooha.

