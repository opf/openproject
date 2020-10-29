# frozen_string_literal: true

require 'spec_helper'

require 'support/env'
require 'support/match_matcher'
require 'support/expand_matcher'
require 'support/pattern'
require 'support/generate_template_matcher'
require 'support/scan_matcher'

describe Mustermann::Grape do
  extend Support::Pattern

  pattern '' do
    it { should     match('')  }
    it { should_not match('/') }

    it { should generate_template('') }

    it { should respond_to(:expand)       }
    it { should respond_to(:to_templates) }
  end

  pattern '/' do
    it { should     match('/')    }
    it { should_not match('/foo') }
  end

  pattern '/foo' do
    it { should     match('/foo')     }
    it { should_not match('/bar')     }
    it { should_not match('/foo.bar') }
  end

  pattern '/foo/bar' do
    it { should     match('/foo/bar')   }
    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }
  end

  pattern '/foo\/bar' do
    it { should match('/foo/bar')   }
    it { should match('/foo%2Fbar') }
    it { should match('/foo%2fbar') }
  end

  pattern '/:foo' do
    it { should match('/foo')       .capturing foo: 'foo'       }
    it { should match('/bar')       .capturing foo: 'bar'       }
    it { should match('/%0Afoo')    .capturing foo: '%0Afoo'    }
    it { should match('/foo%2Fbar') .capturing foo: 'foo%2Fbar' }

    it { should_not match('/foo.bar') }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }

    it { should generate_template('/{foo}') }
  end

  pattern '/föö' do
    it { should match('/f%C3%B6%C3%B6') }
  end

  pattern '/:foo/:bar' do
    it { should match('/foo/bar') .capturing foo: 'foo', bar: 'bar' }
    it { should_not match('/foo.bar/bar.foo')       }
    it { should_not match('/user@example.com/name') }
    it { should_not match('/10.1/te.st')            }
    it { should_not match('/10.1.2/te.st')          }

    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }

    example { pattern.params('/bar/foo').should be == { 'foo' => 'bar', 'bar' => 'foo' } }
    example { pattern.params('').should be_nil }

    it { should generate_template('/{foo}/{bar}') }
  end

  pattern '/{foo}/{bar}' do
    it { should match('/foo/bar')               .capturing foo: 'foo',              bar: 'bar'     }
    it { should match('/foo.bar/bar.foo')       .capturing foo: 'foo.bar',          bar: 'bar.foo' }
    it { should match('/user@example.com/name') .capturing foo: 'user@example.com', bar: 'name'    }
    it { should match('/10.1/te.st')            .capturing foo: '10.1',             bar: 'te.st'   }
    it { should match('/10.1.2/te.st')          .capturing foo: '10.1.2',           bar: 'te.st'   }

    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }

    example { pattern.params('/bar/foo').should be == { 'foo' => 'bar', 'bar' => 'foo' } }
    example { pattern.params('').should be_nil }

    it { should generate_template('/{foo}/{bar}') }
  end

  pattern '/hello/:person' do
    it { should match('/hello/Frank').capturing person: 'Frank' }
    it { should generate_template('/hello/{person}') }
  end

  pattern '/hello/{person}' do
    it { should match('/hello/Frank').capturing person: 'Frank' }
    it { should generate_template('/hello/{person}') }
  end

  pattern '/?:foo?/?:bar?' do
    it { should match('/hello/world') .capturing foo: 'hello', bar: 'world' }
    it { should match('/hello')       .capturing foo: 'hello', bar: nil     }
    it { should match('/')            .capturing foo: nil,     bar: nil     }
    it { should match('')             .capturing foo: nil,     bar: nil     }

    it { should expand(foo: 'hello')               .to('/hello/')      }
    it { should expand(foo: 'hello', bar: 'world') .to('/hello/world') }
    it { should expand(bar: 'world')               .to('//world')      }
    it { should expand                             .to('//')           }
    it { should_not expand(baz: '') }

    it { should_not match('/hello/world/') }
    it { should generate_templates('', '/', '//', '//{bar}', '/{bar}', '/{foo}', '/{foo}/', '/{foo}/{bar}', '/{foo}{bar}', '{bar}', '{foo}', '{foo}/', '{foo}/{bar}', '{foo}{bar}') }
  end

  pattern '/:foo_bar' do
    it { should match('/hello').capturing foo_bar: 'hello' }
    it { should generate_template('/{foo_bar}') }
  end

  pattern '/{foo.bar}' do
    it { should match('/hello').capturing "foo.bar": 'hello' }
    it { should generate_template('/{foo.bar}') }
  end

  pattern '/*' do
    it { should match('/')        .capturing splat: '' }
    it { should match('/foo')     .capturing splat: 'foo' }
    it { should match('/foo/bar') .capturing splat: 'foo/bar' }
    it { should generate_template('/{+splat}') }

    example { pattern.params('/foo').should be == { 'splat' => ['foo'] } }
  end

  pattern '/{+splat}' do
    it { should match('/')        .capturing splat: '' }
    it { should match('/foo')     .capturing splat: 'foo' }
    it { should match('/foo/bar') .capturing splat: 'foo/bar' }
    it { should generate_template('/{+splat}') }

    example { pattern.params('/foo').should be == { 'splat' => ['foo'] } }
  end

  pattern '/*foo' do
    it { should match('/')        .capturing foo: ''        }
    it { should match('/foo')     .capturing foo: 'foo'     }
    it { should match('/foo/bar') .capturing foo: 'foo/bar' }
    it { should generate_template('/{+foo}') }

    example { pattern.params('/foo')     .should be == { 'foo' => 'foo'     } }
    example { pattern.params('/foo/bar') .should be == { 'foo' => 'foo/bar' } }
  end

  pattern '/{+foo}' do
    it { should match('/')        .capturing foo: ''        }
    it { should match('/foo')     .capturing foo: 'foo'     }
    it { should match('/foo/bar') .capturing foo: 'foo/bar' }
    it { should generate_template('/{+foo}') }

    example { pattern.params('/foo')     .should be == { 'foo' => 'foo'     } }
    example { pattern.params('/foo/bar') .should be == { 'foo' => 'foo/bar' } }
  end

  pattern '/*foo/*bar' do
    it { should match('/foo/bar') .capturing foo: 'foo', bar: 'bar' }
    it { should generate_template('/{+foo}/{+bar}') }
  end

  pattern '/{+foo}/{+bar}' do
    it { should match('/foo/bar') .capturing foo: 'foo', bar: 'bar' }
    it { should generate_template('/{+foo}/{+bar}') }
  end

  pattern '/:foo/*' do
    it { should match('/foo/bar/baz')     .capturing foo: 'foo',   splat: 'bar/baz'   }
    it { should match('/foo/')            .capturing foo: 'foo',   splat: ''          }
    it { should match('/h%20w/h%20a%20y') .capturing foo: 'h%20w', splat: 'h%20a%20y' }
    it { should_not match('/foo') }
    it { should generate_template('/{foo}/{+splat}') }

    example { pattern.params('/bar/foo').should be == { 'splat' => ['foo'], 'foo' => 'bar' } }
    example { pattern.params('/bar/foo/f%20o').should be == { 'splat' => ['foo/f o'], 'foo' => 'bar' } }
  end

  pattern '/{foo}/*' do
    it { should match('/foo/bar/baz')     .capturing foo: 'foo',   splat: 'bar/baz'   }
    it { should match('/foo/')            .capturing foo: 'foo',   splat: ''          }
    it { should match('/h%20w/h%20a%20y') .capturing foo: 'h%20w', splat: 'h%20a%20y' }
    it { should_not match('/foo') }
    it { should generate_template('/{foo}/{+splat}') }

    example { pattern.params('/bar/foo').should be == { 'splat' => ['foo'], 'foo' => 'bar' } }
    example { pattern.params('/bar/foo/f%20o').should be == { 'splat' => ['foo/f o'], 'foo' => 'bar' } }
  end

  pattern '/test$/' do
    it { should match('/test$/') }
  end

  pattern '/te+st/' do
    it { should     match('/te+st/') }
    it { should_not match('/test/')  }
    it { should_not match('/teest/') }
  end

  pattern '/path with spaces' do
    it { should match('/path%20with%20spaces') }
    it { should match('/path%2Bwith%2Bspaces') }
    it { should match('/path+with+spaces')     }

    it { should generate_template('/path%20with%20spaces') }
  end

  pattern '/foo&bar' do
    it { should match('/foo&bar') }
  end

  pattern '/foo\{bar' do
    it { should match('/foo%7Bbar') }
  end

  pattern '/*/:foo/*/*' do
    it { should match('/bar/foo/bling/baz/boom') }

    it 'should capture all splat parts' do
      match = pattern.match('/bar/foo/bling/baz/boom')
      match.captures.should be == ['bar', 'foo', 'bling', 'baz/boom']
      match.names.should be == %w[splat foo]
    end

    it 'should map to proper params' do
      pattern.params('/bar/foo/bling/baz/boom').should be == {
        'foo' => 'foo', 'splat' => ['bar', 'bling', 'baz/boom']
      }
    end
  end

  pattern '/{+splat}/{foo}/{+splat}/{+splat}' do
    it { should match('/bar/foo/bling/baz/boom') }

    it 'should capture all splat parts' do
      match = pattern.match('/bar/foo/bling/baz/boom')
      match.captures.should be == ['bar', 'foo', 'bling', 'baz/boom']
      match.names.should be == %w[splat foo]
    end

    it 'should map to proper params' do
      pattern.params('/bar/foo/bling/baz/boom').should be == {
        'foo' => 'foo', 'splat' => ['bar', 'bling', 'baz/boom']
      }
    end
  end

  pattern '/test.bar' do
    it { should     match('/test.bar') }
    it { should_not match('/test0bar') }
  end

  pattern '/:file.:ext' do
    it { should match('/pony.jpg')   .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2Ejpg') .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2ejpg') .capturing file: 'pony', ext: 'jpg' }

    it { should match('/pony%E6%AD%A3%2Ejpg') .capturing file: 'pony%E6%AD%A3', ext: 'jpg' }
    it { should match('/pony%e6%ad%a3%2ejpg') .capturing file: 'pony%e6%ad%a3', ext: 'jpg' }
    it { should match('/pony正%2Ejpg')        .capturing file: 'pony正',         ext: 'jpg' }
    it { should match('/pony正%2ejpg')        .capturing file: 'pony正',         ext: 'jpg' }

    it { should_not match('/pony正..jpg') }
    it { should_not match('/.jpg') }
  end

  pattern '/(:a)x?' do
    it { should match('/a')     .capturing a: 'a'   }
    it { should match('/xa')    .capturing a: 'xa'  }
    it { should match('/axa')   .capturing a: 'axa' }

    it { should generate_template('/{a}x') }
    it { should generate_template('/{a}')  }
  end

  pattern '/:user(@:host)?' do
    it { should match('/foo@bar') .capturing user: 'foo', host: 'bar' }
    it { should_not match('/foo.foo@bar') }
    it { should_not match('/foo@bar.bar') }

    it { should generate_template('/{user}')        }
    it { should generate_template('/{user}@{host}') }
  end

  pattern '/:file(.:ext)?' do
    it { should match('/pony')           .capturing file: 'pony', ext: nil   }
    it { should match('/pony.jpg')       .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2Ejpg')     .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2ejpg')     .capturing file: 'pony', ext: 'jpg' }
    it { should_not match('/pony.png.jpg') }
    it { should_not match('/pony.')        }
    it { should_not match('/.jpg')         }

    it { should     generate_template('/{file}')       }
    it { should     generate_template('/{file}.{ext}') }
    it { should_not generate_template('/{file}.')      }
  end

  pattern '/:id/test.bar' do
    it { should match('/3/test.bar')   .capturing id: '3'   }
    it { should match('/2/test.bar')   .capturing id: '2'   }
    it { should match('/2E/test.bar')  .capturing id: '2E'  }
    it { should match('/2e/test.bar')  .capturing id: '2e'  }
    it { should match('/%2E/test.bar') .capturing id: '%2E' }
  end

  pattern '/10/:id' do
    it { should match('/10/test') .capturing id: 'test' }
    it { should_not match('/10/te.st') }
  end

  pattern '/10.1/:id' do
    it { should match('/10.1/test') .capturing id: 'test' }
    it { should_not match('/10.1/te.st') }
  end

  pattern '/:foo.:bar/:id' do
    it { should_not match('/10.1/te.st')   }
    it { should_not match('/10.1.2/te.st') }
  end

  pattern '/:a/:b.?:c?' do
    it { should match('/a/b')     .capturing a: 'a',   b: 'b', c: nil }
    it { should match('/a/b.c')   .capturing a: 'a',   b: 'b', c: 'c' }
    it { should_not match('/a.b/c')     }
    it { should_not match('/a.b/c.d')   }
    it { should_not match('/a.b/c.d/e') }
  end

  pattern '/:a(foo:b)?' do
    it { should match('/barfoobar')       .capturing a: 'bar',       b: 'bar' }
    it { should match('/barfoobarfoobar') .capturing a: 'barfoobar', b: 'bar' }
    it { should match('/bar')             .capturing a: 'bar',       b: nil   }
    it { should_not match('/') }
  end

  pattern '/foo?' do
    it { should     match('/fo')   }
    it { should     match('/foo')  }
    it { should_not match('')      }
    it { should_not match('/')     }
    it { should_not match('/f')    }
    it { should_not match('/fooo') }
  end

  pattern '/foo\?' do
    it { should     match('/foo?')  }
    it { should_not match('/foo\?') }
    it { should_not match('/fo')    }
    it { should_not match('/foo')   }
    it { should_not match('')       }
    it { should_not match('/')      }
    it { should_not match('/f')     }
    it { should_not match('/fooo')  }
  end

  pattern '/foo\\\?' do
    it { should     match('/foo%5c') }
    it { should     match('/foo')    }
    it { should_not match('/foo\?')  }
    it { should_not match('/fo')     }
    it { should_not match('')        }
    it { should_not match('/')       }
    it { should_not match('/f')      }
    it { should_not match('/fooo')   }
  end

  pattern '/\(' do
    it { should match('/(') }
  end

  pattern '/\(?' do
    it { should match('/(') }
    it { should match('/')  }
  end

  pattern '/(\()?' do
    it { should match('/(') }
    it { should match('/')  }
  end

  pattern '/(\(\))?' do
    it { should     match('/')   }
    it { should     match('/()') }
    it { should_not match('/(')  }
  end

  pattern '/\(\)?' do
    it { should     match('/(')  }
    it { should     match('/()') }
    it { should_not match('/')   }
  end

  pattern '/\*' do
    it { should     match('/*') }
    it { should_not match('/a') }
  end

  pattern '/\*/*' do
    it { should     match('/*/b/c') }
    it { should_not match('/a/b/c') }
  end

  pattern '/\:foo' do
    it { should     match('/:foo') }
    it { should_not match('/foo')  }
  end

  pattern '/:fOO' do
    it { should match('/a').capturing fOO: 'a' }
  end

  pattern '/:_X' do
    it { should match('/a').capturing _X: 'a' }
  end

  pattern '/:f00' do
    it { should match('/a').capturing f00: 'a' }
  end

  pattern '/:foo(/:bar)?/:baz?' do
    it { should match('/foo/bar/baz').capturing foo: 'foo', bar: 'bar', baz: 'baz' }
  end

  pattern '/(foo|bar)' do
    it { should match('/foo') }
    it { should match('/bar') }
  end

  pattern '/(foo\\|bar)' do
    it { should match             '/foo%7Cbar' }
    it { should generate_template '/foo%7Cbar' }

    it { should_not match('/foo') }
    it { should_not match('/bar') }

    it { should_not generate_template('/foo') }
    it { should_not generate_template('/bar') }
  end

  pattern '/(:a/:b|:c)' do
    it { should match('/foo')     .capturing c: 'foo'           }
    it { should match('/foo/bar') .capturing a: 'foo', b: 'bar' }

    it { should expand(a: 'foo', b: 'bar') .to('/foo/bar') }
    it { should expand(c: 'foo')           .to('/foo')     }
    it { should_not expand(a: 'foo', b: 'bar', c: 'baz')   }
  end

  pattern '/:a/:b|:c' do
    it { should match('foo')      .capturing c: 'foo'           }
    it { should match('/foo/bar') .capturing a: 'foo', b: 'bar' }

    it { should generate_template('/{a}/{b}') }
    it { should generate_template('{c}')      }

    it { should expand(a: 'foo', b: 'bar') .to('/foo/bar') }
    it { should expand(c: 'foo')           .to('foo')      }
    it { should_not expand(a: 'foo', b: 'bar', c: 'baz')   }
  end

  pattern '/:foo', capture: /\d+/ do
    it { should match('/1')   .capturing foo: '1'   }
    it { should match('/123') .capturing foo: '123' }

    it { should_not match('/')    }
    it { should_not match('/foo') }
  end

  pattern '/:foo', capture: /\d+/ do
    it { should match('/1')   .capturing foo: '1'   }
    it { should match('/123') .capturing foo: '123' }

    it { should_not match('/')    }
    it { should_not match('/foo') }
  end

  pattern '/:foo', capture: '1' do
    it { should match('/1').capturing foo: '1' }

    it { should_not match('/')    }
    it { should_not match('/foo') }
    it { should_not match('/123') }
  end

  pattern '/:foo', capture: 'a.b' do
    it { should match('/a.b')   .capturing foo: 'a.b'   }
    it { should match('/a%2Eb') .capturing foo: 'a%2Eb' }
    it { should match('/a%2eb') .capturing foo: 'a%2eb' }

    it { should_not match('/ab')   }
    it { should_not match('/afb')  }
    it { should_not match('/a1b')  }
    it { should_not match('/a.bc') }
  end

  pattern '/:foo(/:bar)?', capture: :alpha do
    it { should match('/abc') .capturing foo: 'abc', bar: nil }
    it { should match('/a/b') .capturing foo: 'a',   bar: 'b' }
    it { should match('/a')   .capturing foo: 'a',   bar: nil }

    it { should_not match('/1/2') }
    it { should_not match('/a/2') }
    it { should_not match('/1/b') }
    it { should_not match('/1')   }
    it { should_not match('/1/')  }
    it { should_not match('/a/')  }
    it { should_not match('//a')  }
  end

  pattern '/:foo', capture: ['foo', 'bar', /\d+/] do
    it { should match('/1')   .capturing foo: '1'   }
    it { should match('/123') .capturing foo: '123' }
    it { should match('/foo') .capturing foo: 'foo' }
    it { should match('/bar') .capturing foo: 'bar' }

    it { should_not match('/')     }
    it { should_not match('/baz')  }
    it { should_not match('/foo1') }
  end

  pattern '/:foo:bar:baz', capture: { foo: :alpha, bar: /\d+/ } do
    it { should match('/ab123xy-1') .capturing foo: 'ab', bar: '123', baz: 'xy-1' }
    it { should match('/ab123')     .capturing foo: 'ab', bar: '12',  baz: '3'    }
    it { should_not match('/123abcxy-1') }
    it { should_not match('/abcxy-1')    }
    it { should_not match('/abc1')       }
  end

  pattern '/:foo', capture: { foo: ['foo', 'bar', /\d+/] } do
    it { should match('/1')   .capturing foo: '1'   }
    it { should match('/123') .capturing foo: '123' }
    it { should match('/foo') .capturing foo: 'foo' }
    it { should match('/bar') .capturing foo: 'bar' }

    it { should_not match('/')     }
    it { should_not match('/baz')  }
    it { should_not match('/foo1') }
  end

  pattern '/:file(.:ext)?', capture: { ext: %w[jpg png] } do
    it { should match('/pony')         .capturing file: 'pony',     ext: nil   }
    it { should match('/pony.jpg')     .capturing file: 'pony',     ext: 'jpg' }
    it { should match('/pony%2Ejpg')   .capturing file: 'pony',     ext: 'jpg' }
    it { should match('/pony%2ejpg')   .capturing file: 'pony',     ext: 'jpg' }
    it { should match('/pony.png')     .capturing file: 'pony',     ext: 'png' }
    it { should match('/pony%2Epng')   .capturing file: 'pony',     ext: 'png' }
    it { should match('/pony%2epng')   .capturing file: 'pony',     ext: 'png' }
    it { should_not match('/pony.png.jpg') }
    it { should_not match('/pony.jpg.png') }
    it { should_not match('/pony.gif')     }
    it { should_not match('/pony.')        }
    it { should_not match('.jpg')          }
  end

  pattern '/:file:ext?', capture: { ext: ['.jpg', '.png', '.tar.gz'] } do
    it { should match('/pony')         .capturing file: 'pony',     ext: nil       }
    it { should match('/pony.jpg')     .capturing file: 'pony',     ext: '.jpg'    }
    it { should match('/pony.png')     .capturing file: 'pony',     ext: '.png'    }
    it { should match('/pony.tar.gz')  .capturing file: 'pony',     ext: '.tar.gz' }
    it { should_not match('/pony.png.jpg') }
    it { should_not match('/pony.jpg.png') }
    it { should_not match('/pony.gif')     }
    it { should_not match('/pony.')        }
    it { should_not match('/.jpg')         }
  end

  pattern '/:a(@:b)?', capture: { b: /\d+/ } do
    it { should match('/a')     .capturing a: 'a',   b: nil }
    it { should match('/a@1')   .capturing a: 'a',   b: '1' }
    it { should match('/a@b')   .capturing a: 'a@b', b: nil }
    it { should match('/a@1@2') .capturing a: 'a@1', b: '2' }
  end

  pattern '/(:a)b?', greedy: false do
    it { should match('/ab').capturing a: 'a' }
  end

  pattern '/:file(.:ext)?', greedy: false do
    it { should match('/pony')           .capturing file: 'pony', ext: nil       }
    it { should match('/pony.jpg')       .capturing file: 'pony', ext: 'jpg'     }
    it { should_not match('/pony.png.jpg') }
  end

  pattern '/auth/*', except: '/auth/login' do
    it { should     match('/auth/admin')  }
    it { should     match('/auth/foobar') }
    it { should_not match('/auth/login')  }
  end

  pattern '/:foo/:bar', except: '/:bar/20' do
    it { should match('/foo/bar').capturing foo: 'foo', bar: 'bar' }
    it { should_not match('/20/20') }
  end

  pattern '/foo?', uri_decode: false do
    it { should     match('/foo')  }
    it { should     match('/fo')   }
    it { should_not match('/foo?') }
  end

  pattern '/foo/bar', uri_decode: false do
    it { should     match('/foo/bar')   }
    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }
  end

  pattern '/path with spaces', uri_decode: false do
    it { should     match('/path with spaces')     }
    it { should_not match('/path%20with%20spaces') }
    it { should_not match('/path%2Bwith%2Bspaces') }
    it { should_not match('/path+with+spaces')     }
  end

  pattern '/path with spaces', space_matches_plus: false do
    it { should     match('/path%20with%20spaces') }
    it { should_not match('/path%2Bwith%2Bspaces') }
    it { should_not match('/path+with+spaces')     }
  end

  context 'invalid syntax' do
    example 'unexpected closing parenthesis' do
      expect { Mustermann::Grape.new('foo)bar') }
        .to raise_error(Mustermann::ParseError, 'unexpected ) while parsing "foo)bar"')
    end

    example 'missing closing parenthesis' do
      expect { Mustermann::Grape.new('foo(bar') }
        .to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "foo(bar"')
    end

    example 'missing unescaped closing parenthesis' do
      expect { Mustermann::Grape.new('foo(bar\)') }
        .to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "foo(bar\\\\)"')
    end

    example '? at beginning of route' do
      expect { Mustermann::Grape.new('?foobar') }
        .to raise_error(Mustermann::ParseError, 'unexpected ? while parsing "?foobar"')
    end

    example 'double ?' do
      expect { Mustermann::Grape.new('foo??bar') }
        .to raise_error(Mustermann::ParseError, 'unexpected ? while parsing "foo??bar"')
    end

    example 'dangling escape' do
      expect { Mustermann::Grape.new('foo\\') }
        .to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "foo\\\\"')
    end
  end

  context 'invalid capture names' do
    example 'empty name' do
      expect { Mustermann::Grape.new('/:/') }
        .to raise_error(Mustermann::CompileError, "capture name can't be empty: \"/:/\"")
    end

    example 'named splat' do
      expect { Mustermann::Grape.new('/:splat/') }
        .to raise_error(Mustermann::CompileError, "capture name can't be splat: \"/:splat/\"")
    end

    example 'named captures' do
      expect { Mustermann::Grape.new('/:captures/') }
        .to raise_error(Mustermann::CompileError, "capture name can't be captures: \"/:captures/\"")
    end

    example 'with capital letter' do
      expect { Mustermann::Grape.new('/:Foo/') }
        .to raise_error(Mustermann::CompileError, 'capture name must start with underscore or lower case letter: "/:Foo/"')
    end

    example 'with integer' do
      expect { Mustermann::Grape.new('/:1a/') }
        .to raise_error(Mustermann::CompileError, 'capture name must start with underscore or lower case letter: "/:1a/"')
    end

    example 'same name twice' do
      expect { Mustermann::Grape.new('/:foo(/:bar)?/:bar?') }
        .to raise_error(Mustermann::CompileError, "can't use the same capture name twice: \"/:foo(/:bar)?/:bar?\"")
    end
  end

  context 'Regexp compatibility' do
    describe :=== do
      example('non-matching') { Mustermann::Grape.new('/')     .should_not be === '/foo' }
      example('matching')     { Mustermann::Grape.new('/:foo') .should     be === '/foo' }
    end

    describe :=~ do
      example('non-matching') { Mustermann::Grape.new('/')     .should_not be =~ '/foo' }
      example('matching')     { Mustermann::Grape.new('/:foo') .should     be =~ '/foo' }

      context 'String#=~' do
        example('non-matching') { '/foo'.should_not be =~ Mustermann::Grape.new('/') }
        example('matching')     { '/foo'.should     be =~ Mustermann::Grape.new('/:foo') }
      end
    end

    describe :to_regexp do
      example('empty pattern') { Mustermann::Grape.new('').to_regexp.should be == /\A(?-mix:)\Z/ }

      context 'Regexp.try_convert' do
        example('empty pattern') { Regexp.try_convert(Mustermann::Grape.new('')).should be == /\A(?-mix:)\Z/ }
      end
    end
  end

  context 'Proc compatibility' do
    describe :to_proc do
      example { Mustermann::Grape.new('/').to_proc.should be_a(Proc) }
      example('non-matching') { Mustermann::Grape.new('/')     .to_proc.call('/foo').should be == false }
      example('matching')     { Mustermann::Grape.new('/:foo') .to_proc.call('/foo').should be == true  }
    end
  end

  context 'peeking' do
    subject(:pattern) { Mustermann::Grape.new(':name') }

    describe :peek_size do
      example { pattern.peek_size('foo bar/blah')   .should be == 'foo bar'.size }
      example { pattern.peek_size('foo%20bar/blah') .should be == 'foo%20bar'.size }
      example { pattern.peek_size('/foo bar')       .should be_nil }
    end

    describe :peek_match do
      example { pattern.peek_match('foo bar/blah')   .to_s .should be == 'foo bar' }
      example { pattern.peek_match('foo%20bar/blah') .to_s .should be == 'foo%20bar' }
      example { pattern.peek_match('/foo bar')             .should be_nil }
    end

    describe :peek_params do
      example { pattern.peek_params('foo bar/blah')   .should be == [{ 'name' => 'foo bar' }, 'foo bar'.size] }
      example { pattern.peek_params('foo%20bar/blah') .should be == [{ 'name' => 'foo bar' }, 'foo%20bar'.size] }
      example { pattern.peek_params('/foo bar')       .should be_nil }
    end
  end
end
