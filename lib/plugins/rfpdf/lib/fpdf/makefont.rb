#!/usr/bin/env ruby
#-- encoding: UTF-8
#
# Utility to generate font definition files
# Version: 1.1
# Date:    2006-07-19
#
# Changelog:
#  Version 1.1 - Brian Ollenberger
#   - Fixed a very small bug in MakeFont for generating FontDef.diff.

Charencodings = {
# Central Europe
    'cp1250' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'Euro',           '.notdef',        'quotesinglbase', '.notdef',
        'quotedblbase',   'ellipsis',       'dagger',         'daggerdbl',
        '.notdef',        'perthousand',    'Scaron',         'guilsinglleft',
        'Sacute',         'Tcaron',         'Zcaron',         'Zacute',
        '.notdef',        'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        '.notdef',        'trademark',      'scaron',         'guilsinglright',
        'sacute',         'tcaron',         'zcaron',         'zacute',
        'space',          'caron',          'breve',          'Lslash',
        'currency',       'Aogonek',        'brokenbar',      'section',
        'dieresis',       'copyright',      'Scedilla',       'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'Zdotaccent',
        'degree',         'plusminus',      'ogonek',         'lslash',
        'acute',          'mu',             'paragraph',      'periodcentered',
        'cedilla',        'aogonek',        'scedilla',       'guillemotright',
        'Lcaron',         'hungarumlaut',   'lcaron',         'zdotaccent',
        'Racute',         'Aacute',         'Acircumflex',    'Abreve',
        'Adieresis',      'Lacute',         'Cacute',         'Ccedilla',
        'Ccaron',         'Eacute',         'Eogonek',        'Edieresis',
        'Ecaron',         'Iacute',         'Icircumflex',    'Dcaron',
        'Dcroat',         'Nacute',         'Ncaron',         'Oacute',
        'Ocircumflex',    'Ohungarumlaut',  'Odieresis',      'multiply',
        'Rcaron',         'Uring',          'Uacute',         'Uhungarumlaut',
        'Udieresis',      'Yacute',         'Tcommaaccent',   'germandbls',
        'racute',         'aacute',         'acircumflex',    'abreve',
        'adieresis',      'lacute',         'cacute',         'ccedilla',
        'ccaron',         'eacute',         'eogonek',        'edieresis',
        'ecaron',         'iacute',         'icircumflex',    'dcaron',
        'dcroat',         'nacute',         'ncaron',         'oacute',
        'ocircumflex',    'ohungarumlaut',  'odieresis',      'divide',
        'rcaron',         'uring',          'uacute',         'uhungarumlaut',
        'udieresis',      'yacute',         'tcommaaccent',   'dotaccent'
    ],
# Cyrillic
    'cp1251' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'afii10051',      'afii10052',      'quotesinglbase', 'afii10100',
        'quotedblbase',   'ellipsis',       'dagger',         'daggerdbl',
        'Euro',           'perthousand',    'afii10058',      'guilsinglleft',
        'afii10059',      'afii10061',      'afii10060',      'afii10145',
        'afii10099',      'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        '.notdef',        'trademark',      'afii10106',      'guilsinglright',
        'afii10107',      'afii10109',      'afii10108',      'afii10193',
        'space',          'afii10062',      'afii10110',      'afii10057',
        'currency',       'afii10050',      'brokenbar',      'section',
        'afii10023',      'copyright',      'afii10053',      'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'afii10056',
        'degree',         'plusminus',      'afii10055',      'afii10103',
        'afii10098',      'mu',             'paragraph',      'periodcentered',
        'afii10071',      'afii61352',      'afii10101',      'guillemotright',
        'afii10105',      'afii10054',      'afii10102',      'afii10104',
        'afii10017',      'afii10018',      'afii10019',      'afii10020',
        'afii10021',      'afii10022',      'afii10024',      'afii10025',
        'afii10026',      'afii10027',      'afii10028',      'afii10029',
        'afii10030',      'afii10031',      'afii10032',      'afii10033',
        'afii10034',      'afii10035',      'afii10036',      'afii10037',
        'afii10038',      'afii10039',      'afii10040',      'afii10041',
        'afii10042',      'afii10043',      'afii10044',      'afii10045',
        'afii10046',      'afii10047',      'afii10048',      'afii10049',
        'afii10065',      'afii10066',      'afii10067',      'afii10068',
        'afii10069',      'afii10070',      'afii10072',      'afii10073',
        'afii10074',      'afii10075',      'afii10076',      'afii10077',
        'afii10078',      'afii10079',      'afii10080',      'afii10081',
        'afii10082',      'afii10083',      'afii10084',      'afii10085',
        'afii10086',      'afii10087',      'afii10088',      'afii10089',
        'afii10090',      'afii10091',      'afii10092',      'afii10093',
        'afii10094',      'afii10095',      'afii10096',      'afii10097'
    ],
# Western Europe
    'cp1252' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'Euro',           '.notdef',        'quotesinglbase', 'florin',
        'quotedblbase',   'ellipsis',       'dagger',         'daggerdbl',
        'circumflex',     'perthousand',    'Scaron',         'guilsinglleft',
        'OE',             '.notdef',        'Zcaron',         '.notdef',
        '.notdef',        'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        'tilde',          'trademark',      'scaron',         'guilsinglright',
        'oe',             '.notdef',        'zcaron',         'Ydieresis',
        'space',          'exclamdown',     'cent',           'sterling',
        'currency',       'yen',            'brokenbar',      'section',
        'dieresis',       'copyright',      'ordfeminine',    'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'macron',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'acute',          'mu',             'paragraph',      'periodcentered',
        'cedilla',        'onesuperior',    'ordmasculine',   'guillemotright',
        'onequarter',     'onehalf',        'threequarters',  'questiondown',
        'Agrave',         'Aacute',         'Acircumflex',    'Atilde',
        'Adieresis',      'Aring',          'AE',             'Ccedilla',
        'Egrave',         'Eacute',         'Ecircumflex',    'Edieresis',
        'Igrave',         'Iacute',         'Icircumflex',    'Idieresis',
        'Eth',            'Ntilde',         'Ograve',         'Oacute',
        'Ocircumflex',    'Otilde',         'Odieresis',      'multiply',
        'Oslash',         'Ugrave',         'Uacute',         'Ucircumflex',
        'Udieresis',      'Yacute',         'Thorn',          'germandbls',
        'agrave',         'aacute',         'acircumflex',    'atilde',
        'adieresis',      'aring',          'ae',             'ccedilla',
        'egrave',         'eacute',         'ecircumflex',    'edieresis',
        'igrave',         'iacute',         'icircumflex',    'idieresis',
        'eth',            'ntilde',         'ograve',         'oacute',
        'ocircumflex',    'otilde',         'odieresis',      'divide',
        'oslash',         'ugrave',         'uacute',         'ucircumflex',
        'udieresis',      'yacute',         'thorn',          'ydieresis'
    ],
# Greek
    'cp1253' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'Euro',           '.notdef',        'quotesinglbase', 'florin',
        'quotedblbase',   'ellipsis',       'dagger',         'daggerdbl',
        '.notdef',        'perthousand',    '.notdef',        'guilsinglleft',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        '.notdef',        'trademark',      '.notdef',        'guilsinglright',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'dieresistonos',  'Alphatonos',     'sterling',
        'currency',       'yen',            'brokenbar',      'section',
        'dieresis',       'copyright',      '.notdef',        'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'afii00208',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'tonos',          'mu',             'paragraph',      'periodcentered',
        'Epsilontonos',   'Etatonos',       'Iotatonos',      'guillemotright',
        'Omicrontonos',   'onehalf',        'Upsilontonos',   'Omegatonos',
        'iotadieresistonos','Alpha',          'Beta',           'Gamma',
        'Delta',          'Epsilon',        'Zeta',           'Eta',
        'Theta',          'Iota',           'Kappa',          'Lambda',
        'Mu',             'Nu',             'Xi',             'Omicron',
        'Pi',             'Rho',            '.notdef',        'Sigma',
        'Tau',            'Upsilon',        'Phi',            'Chi',
        'Psi',            'Omega',          'Iotadieresis',   'Upsilondieresis',
        'alphatonos',     'epsilontonos',   'etatonos',       'iotatonos',
        'upsilondieresistonos','alpha',          'beta',           'gamma',
        'delta',          'epsilon',        'zeta',           'eta',
        'theta',          'iota',           'kappa',          'lambda',
        'mu',             'nu',             'xi',             'omicron',
        'pi',             'rho',            'sigma1',         'sigma',
        'tau',            'upsilon',        'phi',            'chi',
        'psi',            'omega',          'iotadieresis',   'upsilondieresis',
        'omicrontonos',   'upsilontonos',   'omegatonos',     '.notdef'
    ],
# Turkish
    'cp1254' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'Euro',           '.notdef',        'quotesinglbase', 'florin',
        'quotedblbase',   'ellipsis',       'dagger',         'daggerdbl',
        'circumflex',     'perthousand',    'Scaron',         'guilsinglleft',
        'OE',             '.notdef',        '.notdef',        '.notdef',
        '.notdef',        'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        'tilde',          'trademark',      'scaron',         'guilsinglright',
        'oe',             '.notdef',        '.notdef',        'Ydieresis',
        'space',          'exclamdown',     'cent',           'sterling',
        'currency',       'yen',            'brokenbar',      'section',
        'dieresis',       'copyright',      'ordfeminine',    'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'macron',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'acute',          'mu',             'paragraph',      'periodcentered',
        'cedilla',        'onesuperior',    'ordmasculine',   'guillemotright',
        'onequarter',     'onehalf',        'threequarters',  'questiondown',
        'Agrave',         'Aacute',         'Acircumflex',    'Atilde',
        'Adieresis',      'Aring',          'AE',             'Ccedilla',
        'Egrave',         'Eacute',         'Ecircumflex',    'Edieresis',
        'Igrave',         'Iacute',         'Icircumflex',    'Idieresis',
        'Gbreve',         'Ntilde',         'Ograve',         'Oacute',
        'Ocircumflex',    'Otilde',         'Odieresis',      'multiply',
        'Oslash',         'Ugrave',         'Uacute',         'Ucircumflex',
        'Udieresis',      'Idotaccent',     'Scedilla',       'germandbls',
        'agrave',         'aacute',         'acircumflex',    'atilde',
        'adieresis',      'aring',          'ae',             'ccedilla',
        'egrave',         'eacute',         'ecircumflex',    'edieresis',
        'igrave',         'iacute',         'icircumflex',    'idieresis',
        'gbreve',         'ntilde',         'ograve',         'oacute',
        'ocircumflex',    'otilde',         'odieresis',      'divide',
        'oslash',         'ugrave',         'uacute',         'ucircumflex',
        'udieresis',      'dotlessi',       'scedilla',       'ydieresis'
    ],
# Hebrew
    'cp1255' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'Euro',           '.notdef',        'quotesinglbase', 'florin',
        'quotedblbase',   'ellipsis',       'dagger',         'daggerdbl',
        'circumflex',     'perthousand',    '.notdef',        'guilsinglleft',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        'tilde',          'trademark',      '.notdef',        'guilsinglright',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclamdown',     'cent',           'sterling',
        'afii57636',      'yen',            'brokenbar',      'section',
        'dieresis',       'copyright',      'multiply',       'guillemotleft',
        'logicalnot',     'sfthyphen',      'registered',     'macron',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'acute',          'mu',             'paragraph',      'middot',
        'cedilla',        'onesuperior',    'divide',         'guillemotright',
        'onequarter',     'onehalf',        'threequarters',  'questiondown',
        'afii57799',      'afii57801',      'afii57800',      'afii57802',
        'afii57793',      'afii57794',      'afii57795',      'afii57798',
        'afii57797',      'afii57806',      '.notdef',        'afii57796',
        'afii57807',      'afii57839',      'afii57645',      'afii57841',
        'afii57842',      'afii57804',      'afii57803',      'afii57658',
        'afii57716',      'afii57717',      'afii57718',      'gereshhebrew',
        'gershayimhebrew','.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'afii57664',      'afii57665',      'afii57666',      'afii57667',
        'afii57668',      'afii57669',      'afii57670',      'afii57671',
        'afii57672',      'afii57673',      'afii57674',      'afii57675',
        'afii57676',      'afii57677',      'afii57678',      'afii57679',
        'afii57680',      'afii57681',      'afii57682',      'afii57683',
        'afii57684',      'afii57685',      'afii57686',      'afii57687',
        'afii57688',      'afii57689',      'afii57690',      '.notdef',
        '.notdef',        'afii299',        'afii300',        '.notdef'
    ],
# Baltic
    'cp1257' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'Euro',           '.notdef',        'quotesinglbase', '.notdef',
        'quotedblbase',   'ellipsis',       'dagger',         'daggerdbl',
        '.notdef',        'perthousand',    '.notdef',        'guilsinglleft',
        '.notdef',        'dieresis',       'caron',          'cedilla',
        '.notdef',        'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        '.notdef',        'trademark',      '.notdef',        'guilsinglright',
        '.notdef',        'macron',         'ogonek',         '.notdef',
        'space',          '.notdef',        'cent',           'sterling',
        'currency',       '.notdef',        'brokenbar',      'section',
        'Oslash',         'copyright',      'Rcommaaccent',   'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'AE',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'acute',          'mu',             'paragraph',      'periodcentered',
        'oslash',         'onesuperior',    'rcommaaccent',   'guillemotright',
        'onequarter',     'onehalf',        'threequarters',  'ae',
        'Aogonek',        'Iogonek',        'Amacron',        'Cacute',
        'Adieresis',      'Aring',          'Eogonek',        'Emacron',
        'Ccaron',         'Eacute',         'Zacute',         'Edotaccent',
        'Gcommaaccent',   'Kcommaaccent',   'Imacron',        'Lcommaaccent',
        'Scaron',         'Nacute',         'Ncommaaccent',   'Oacute',
        'Omacron',        'Otilde',         'Odieresis',      'multiply',
        'Uogonek',        'Lslash',         'Sacute',         'Umacron',
        'Udieresis',      'Zdotaccent',     'Zcaron',         'germandbls',
        'aogonek',        'iogonek',        'amacron',        'cacute',
        'adieresis',      'aring',          'eogonek',        'emacron',
        'ccaron',         'eacute',         'zacute',         'edotaccent',
        'gcommaaccent',   'kcommaaccent',   'imacron',        'lcommaaccent',
        'scaron',         'nacute',         'ncommaaccent',   'oacute',
        'omacron',        'otilde',         'odieresis',      'divide',
        'uogonek',        'lslash',         'sacute',         'umacron',
        'udieresis',      'zdotaccent',     'zcaron',         'dotaccent'
    ],
# Vietnamese
    'cp1258' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'Euro',           '.notdef',        'quotesinglbase', 'florin',
        'quotedblbase',   'ellipsis',       'dagger',         'daggerdbl',
        'circumflex',     'perthousand',    '.notdef',        'guilsinglleft',
        'OE',             '.notdef',        '.notdef',        '.notdef',
        '.notdef',        'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        'tilde',          'trademark',      '.notdef',        'guilsinglright',
        'oe',             '.notdef',        '.notdef',        'Ydieresis',
        'space',          'exclamdown',     'cent',           'sterling',
        'currency',       'yen',            'brokenbar',      'section',
        'dieresis',       'copyright',      'ordfeminine',    'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'macron',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'acute',          'mu',             'paragraph',      'periodcentered',
        'cedilla',        'onesuperior',    'ordmasculine',   'guillemotright',
        'onequarter',     'onehalf',        'threequarters',  'questiondown',
        'Agrave',         'Aacute',         'Acircumflex',    'Abreve',
        'Adieresis',      'Aring',          'AE',             'Ccedilla',
        'Egrave',         'Eacute',         'Ecircumflex',    'Edieresis',
        'gravecomb',      'Iacute',         'Icircumflex',    'Idieresis',
        'Dcroat',         'Ntilde',         'hookabovecomb',  'Oacute',
        'Ocircumflex',    'Ohorn',          'Odieresis',      'multiply',
        'Oslash',         'Ugrave',         'Uacute',         'Ucircumflex',
        'Udieresis',      'Uhorn',          'tildecomb',      'germandbls',
        'agrave',         'aacute',         'acircumflex',    'abreve',
        'adieresis',      'aring',          'ae',             'ccedilla',
        'egrave',         'eacute',         'ecircumflex',    'edieresis',
        'acutecomb',      'iacute',         'icircumflex',    'idieresis',
        'dcroat',         'ntilde',         'dotbelowcomb',   'oacute',
        'ocircumflex',    'ohorn',          'odieresis',      'divide',
        'oslash',         'ugrave',         'uacute',         'ucircumflex',
        'udieresis',      'uhorn',          'dong',           'ydieresis'
    ],
# Thai
    'cp874' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'Euro',           '.notdef',        '.notdef',        '.notdef',
        '.notdef',        'ellipsis',       '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        'quoteleft',      'quoteright',     'quotedblleft',
        'quotedblright',  'bullet',         'endash',         'emdash',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'kokaithai',      'khokhaithai',    'khokhuatthai',
        'khokhwaithai',   'khokhonthai',    'khorakhangthai', 'ngonguthai',
        'chochanthai',    'chochingthai',   'chochangthai',   'sosothai',
        'chochoethai',    'yoyingthai',     'dochadathai',    'topatakthai',
        'thothanthai',    'thonangmonthothai', 'thophuthaothai', 'nonenthai',
        'dodekthai',      'totaothai',      'thothungthai',   'thothahanthai',
        'thothongthai',   'nonuthai',       'bobaimaithai',   'poplathai',
        'phophungthai',   'fofathai',       'phophanthai',    'fofanthai',
        'phosamphaothai', 'momathai',       'yoyakthai',      'roruathai',
        'ruthai',         'lolingthai',     'luthai',         'wowaenthai',
        'sosalathai',     'sorusithai',     'sosuathai',      'hohipthai',
        'lochulathai',    'oangthai',       'honokhukthai',   'paiyannoithai',
        'saraathai',      'maihanakatthai', 'saraaathai',     'saraamthai',
        'saraithai',      'saraiithai',     'sarauethai',     'saraueethai',
        'sarauthai',      'sarauuthai',     'phinthuthai',    '.notdef',
        '.notdef',        '.notdef',        '.notdef',        'bahtthai',
        'saraethai',      'saraaethai',     'saraothai',      'saraaimaimuanthai',
        'saraaimaimalaithai', 'lakkhangyaothai', 'maiyamokthai', 'maitaikhuthai',
        'maiekthai',      'maithothai',     'maitrithai',     'maichattawathai',
        'thanthakhatthai', 'nikhahitthai',  'yamakkanthai',   'fongmanthai',
        'zerothai',       'onethai',        'twothai',        'threethai',
        'fourthai',       'fivethai',       'sixthai',        'seventhai',
        'eightthai',      'ninethai',       'angkhankhuthai', 'khomutthai',
        '.notdef',        '.notdef',        '.notdef',        '.notdef'
    ],
# Western Europe
    'ISO-8859-1' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclamdown',     'cent',           'sterling',
        'currency',       'yen',            'brokenbar',      'section',
        'dieresis',       'copyright',      'ordfeminine',    'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'macron',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'acute',          'mu',             'paragraph',      'periodcentered',
        'cedilla',        'onesuperior',    'ordmasculine',   'guillemotright',
        'onequarter',     'onehalf',        'threequarters',  'questiondown',
        'Agrave',         'Aacute',         'Acircumflex',    'Atilde',
        'Adieresis',      'Aring',          'AE',             'Ccedilla',
        'Egrave',         'Eacute',         'Ecircumflex',    'Edieresis',
        'Igrave',         'Iacute',         'Icircumflex',    'Idieresis',
        'Eth',            'Ntilde',         'Ograve',         'Oacute',
        'Ocircumflex',    'Otilde',         'Odieresis',      'multiply',
        'Oslash',         'Ugrave',         'Uacute',         'Ucircumflex',
        'Udieresis',      'Yacute',         'Thorn',          'germandbls',
        'agrave',         'aacute',         'acircumflex',    'atilde',
        'adieresis',      'aring',          'ae',             'ccedilla',
        'egrave',         'eacute',         'ecircumflex',    'edieresis',
        'igrave',         'iacute',         'icircumflex',    'idieresis',
        'eth',            'ntilde',         'ograve',         'oacute',
        'ocircumflex',    'otilde',         'odieresis',      'divide',
        'oslash',         'ugrave',         'uacute',         'ucircumflex',
        'udieresis',      'yacute',         'thorn',          'ydieresis'
    ],
# Central Europe
    'ISO-8859-2' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'Aogonek',        'breve',          'Lslash',
        'currency',       'Lcaron',         'Sacute',         'section',
        'dieresis',       'Scaron',         'Scedilla',       'Tcaron',
        'Zacute',         'hyphen',         'Zcaron',         'Zdotaccent',
        'degree',         'aogonek',        'ogonek',         'lslash',
        'acute',          'lcaron',         'sacute',         'caron',
        'cedilla',        'scaron',         'scedilla',       'tcaron',
        'zacute',         'hungarumlaut',   'zcaron',         'zdotaccent',
        'Racute',         'Aacute',         'Acircumflex',    'Abreve',
        'Adieresis',      'Lacute',         'Cacute',         'Ccedilla',
        'Ccaron',         'Eacute',         'Eogonek',        'Edieresis',
        'Ecaron',         'Iacute',         'Icircumflex',    'Dcaron',
        'Dcroat',         'Nacute',         'Ncaron',         'Oacute',
        'Ocircumflex',    'Ohungarumlaut',  'Odieresis',      'multiply',
        'Rcaron',         'Uring',          'Uacute',         'Uhungarumlaut',
        'Udieresis',      'Yacute',         'Tcommaaccent',   'germandbls',
        'racute',         'aacute',         'acircumflex',    'abreve',
        'adieresis',      'lacute',         'cacute',         'ccedilla',
        'ccaron',         'eacute',         'eogonek',        'edieresis',
        'ecaron',         'iacute',         'icircumflex',    'dcaron',
        'dcroat',         'nacute',         'ncaron',         'oacute',
        'ocircumflex',    'ohungarumlaut',  'odieresis',      'divide',
        'rcaron',         'uring',          'uacute',         'uhungarumlaut',
        'udieresis',      'yacute',         'tcommaaccent',   'dotaccent'
    ],
# Baltic
    'ISO-8859-4' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'Aogonek',        'kgreenlandic',   'Rcommaaccent',
        'currency',       'Itilde',         'Lcommaaccent',   'section',
        'dieresis',       'Scaron',         'Emacron',        'Gcommaaccent',
        'Tbar',           'hyphen',         'Zcaron',         'macron',
        'degree',         'aogonek',        'ogonek',         'rcommaaccent',
        'acute',          'itilde',         'lcommaaccent',   'caron',
        'cedilla',        'scaron',         'emacron',        'gcommaaccent',
        'tbar',           'Eng',            'zcaron',         'eng',
        'Amacron',        'Aacute',         'Acircumflex',    'Atilde',
        'Adieresis',      'Aring',          'AE',             'Iogonek',
        'Ccaron',         'Eacute',         'Eogonek',        'Edieresis',
        'Edotaccent',     'Iacute',         'Icircumflex',    'Imacron',
        'Dcroat',         'Ncommaaccent',   'Omacron',        'Kcommaaccent',
        'Ocircumflex',    'Otilde',         'Odieresis',      'multiply',
        'Oslash',         'Uogonek',        'Uacute',         'Ucircumflex',
        'Udieresis',      'Utilde',         'Umacron',        'germandbls',
        'amacron',        'aacute',         'acircumflex',    'atilde',
        'adieresis',      'aring',          'ae',             'iogonek',
        'ccaron',         'eacute',         'eogonek',        'edieresis',
        'edotaccent',     'iacute',         'icircumflex',    'imacron',
        'dcroat',         'ncommaaccent',   'omacron',        'kcommaaccent',
        'ocircumflex',    'otilde',         'odieresis',      'divide',
        'oslash',         'uogonek',        'uacute',         'ucircumflex',
        'udieresis',      'utilde',         'umacron',        'dotaccent'
    ],
# Cyrillic
    'ISO-8859-5' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'afii10023',      'afii10051',      'afii10052',
        'afii10053',      'afii10054',      'afii10055',      'afii10056',
        'afii10057',      'afii10058',      'afii10059',      'afii10060',
        'afii10061',      'hyphen',         'afii10062',      'afii10145',
        'afii10017',      'afii10018',      'afii10019',      'afii10020',
        'afii10021',      'afii10022',      'afii10024',      'afii10025',
        'afii10026',      'afii10027',      'afii10028',      'afii10029',
        'afii10030',      'afii10031',      'afii10032',      'afii10033',
        'afii10034',      'afii10035',      'afii10036',      'afii10037',
        'afii10038',      'afii10039',      'afii10040',      'afii10041',
        'afii10042',      'afii10043',      'afii10044',      'afii10045',
        'afii10046',      'afii10047',      'afii10048',      'afii10049',
        'afii10065',      'afii10066',      'afii10067',      'afii10068',
        'afii10069',      'afii10070',      'afii10072',      'afii10073',
        'afii10074',      'afii10075',      'afii10076',      'afii10077',
        'afii10078',      'afii10079',      'afii10080',      'afii10081',
        'afii10082',      'afii10083',      'afii10084',      'afii10085',
        'afii10086',      'afii10087',      'afii10088',      'afii10089',
        'afii10090',      'afii10091',      'afii10092',      'afii10093',
        'afii10094',      'afii10095',      'afii10096',      'afii10097',
        'afii61352',      'afii10071',      'afii10099',      'afii10100',
        'afii10101',      'afii10102',      'afii10103',      'afii10104',
        'afii10105',      'afii10106',      'afii10107',      'afii10108',
        'afii10109',      'section',        'afii10110',      'afii10193'
    ],
# Greek
    'ISO-8859-7' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'quoteleft',      'quoteright',     'sterling',
        '.notdef',        '.notdef',        'brokenbar',      'section',
        'dieresis',       'copyright',      '.notdef',        'guillemotleft',
        'logicalnot',     'hyphen',         '.notdef',        'afii00208',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'tonos',          'dieresistonos',  'Alphatonos',     'periodcentered',
        'Epsilontonos',   'Etatonos',       'Iotatonos',      'guillemotright',
        'Omicrontonos',   'onehalf',        'Upsilontonos',   'Omegatonos',
        'iotadieresistonos','Alpha',          'Beta',           'Gamma',
        'Delta',          'Epsilon',        'Zeta',           'Eta',
        'Theta',          'Iota',           'Kappa',          'Lambda',
        'Mu',             'Nu',             'Xi',             'Omicron',
        'Pi',             'Rho',            '.notdef',        'Sigma',
        'Tau',            'Upsilon',        'Phi',            'Chi',
        'Psi',            'Omega',          'Iotadieresis',   'Upsilondieresis',
        'alphatonos',     'epsilontonos',   'etatonos',       'iotatonos',
        'upsilondieresistonos','alpha',          'beta',           'gamma',
        'delta',          'epsilon',        'zeta',           'eta',
        'theta',          'iota',           'kappa',          'lambda',
        'mu',             'nu',             'xi',             'omicron',
        'pi',             'rho',            'sigma1',         'sigma',
        'tau',            'upsilon',        'phi',            'chi',
        'psi',            'omega',          'iotadieresis',   'upsilondieresis',
        'omicrontonos',   'upsilontonos',   'omegatonos',     '.notdef'
    ],
# Turkish
    'ISO-8859-9' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclamdown',     'cent',           'sterling',
        'currency',       'yen',            'brokenbar',      'section',
        'dieresis',       'copyright',      'ordfeminine',    'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'macron',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'acute',          'mu',             'paragraph',      'periodcentered',
        'cedilla',        'onesuperior',    'ordmasculine',   'guillemotright',
        'onequarter',     'onehalf',        'threequarters',  'questiondown',
        'Agrave',         'Aacute',         'Acircumflex',    'Atilde',
        'Adieresis',      'Aring',          'AE',             'Ccedilla',
        'Egrave',         'Eacute',         'Ecircumflex',    'Edieresis',
        'Igrave',         'Iacute',         'Icircumflex',    'Idieresis',
        'Gbreve',         'Ntilde',         'Ograve',         'Oacute',
        'Ocircumflex',    'Otilde',         'Odieresis',      'multiply',
        'Oslash',         'Ugrave',         'Uacute',         'Ucircumflex',
        'Udieresis',      'Idotaccent',     'Scedilla',       'germandbls',
        'agrave',         'aacute',         'acircumflex',    'atilde',
        'adieresis',      'aring',          'ae',             'ccedilla',
        'egrave',         'eacute',         'ecircumflex',    'edieresis',
        'igrave',         'iacute',         'icircumflex',    'idieresis',
        'gbreve',         'ntilde',         'ograve',         'oacute',
        'ocircumflex',    'otilde',         'odieresis',      'divide',
        'oslash',         'ugrave',         'uacute',         'ucircumflex',
        'udieresis',      'dotlessi',       'scedilla',       'ydieresis'
    ],
# Thai
    'ISO-8859-11' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'kokaithai',      'khokhaithai',    'khokhuatthai',
        'khokhwaithai',   'khokhonthai',    'khorakhangthai', 'ngonguthai',
        'chochanthai',    'chochingthai',   'chochangthai',   'sosothai',
        'chochoethai',    'yoyingthai',     'dochadathai',    'topatakthai',
        'thothanthai',    'thonangmonthothai','thophuthaothai', 'nonenthai',
        'dodekthai',      'totaothai',      'thothungthai',   'thothahanthai',
        'thothongthai',   'nonuthai',       'bobaimaithai',   'poplathai',
        'phophungthai',   'fofathai',       'phophanthai',    'fofanthai',
        'phosamphaothai', 'momathai',       'yoyakthai',      'roruathai',
        'ruthai',         'lolingthai',     'luthai',         'wowaenthai',
        'sosalathai',     'sorusithai',     'sosuathai',      'hohipthai',
        'lochulathai',    'oangthai',       'honokhukthai',   'paiyannoithai',
        'saraathai',      'maihanakatthai', 'saraaathai',     'saraamthai',
        'saraithai',      'saraiithai',     'sarauethai',     'saraueethai',
        'sarauthai',      'sarauuthai',     'phinthuthai',    '.notdef',
        '.notdef',        '.notdef',        '.notdef',        'bahtthai',
        'saraethai',      'saraaethai',     'saraothai',      'saraaimaimuanthai',
        'saraaimaimalaithai','lakkhangyaothai','maiyamokthai',   'maitaikhuthai',
        'maiekthai',      'maithothai',     'maitrithai',     'maichattawathai',
        'thanthakhatthai','nikhahitthai',   'yamakkanthai',   'fongmanthai',
        'zerothai',       'onethai',        'twothai',        'threethai',
        'fourthai',       'fivethai',       'sixthai',        'seventhai',
        'eightthai',      'ninethai',       'angkhankhuthai', 'khomutthai',
        '.notdef',        '.notdef',        '.notdef',        '.notdef'
    ],
# Western Europe
    'ISO-8859-15' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclamdown',     'cent',           'sterling',
        'Euro',           'yen',            'Scaron',         'section',
        'scaron',         'copyright',      'ordfeminine',    'guillemotleft',
        'logicalnot',     'hyphen',         'registered',     'macron',
        'degree',         'plusminus',      'twosuperior',    'threesuperior',
        'Zcaron',         'mu',             'paragraph',      'periodcentered',
        'zcaron',         'onesuperior',    'ordmasculine',   'guillemotright',
        'OE',             'oe',             'Ydieresis',      'questiondown',
        'Agrave',         'Aacute',         'Acircumflex',    'Atilde',
        'Adieresis',      'Aring',          'AE',             'Ccedilla',
        'Egrave',         'Eacute',         'Ecircumflex',    'Edieresis',
        'Igrave',         'Iacute',         'Icircumflex',    'Idieresis',
        'Eth',            'Ntilde',         'Ograve',         'Oacute',
        'Ocircumflex',    'Otilde',         'Odieresis',      'multiply',
        'Oslash',         'Ugrave',         'Uacute',         'Ucircumflex',
        'Udieresis',      'Yacute',         'Thorn',          'germandbls',
        'agrave',         'aacute',         'acircumflex',    'atilde',
        'adieresis',      'aring',          'ae',             'ccedilla',
        'egrave',         'eacute',         'ecircumflex',    'edieresis',
        'igrave',         'iacute',         'icircumflex',    'idieresis',
        'eth',            'ntilde',         'ograve',         'oacute',
        'ocircumflex',    'otilde',         'odieresis',      'divide',
        'oslash',         'ugrave',         'uacute',         'ucircumflex',
        'udieresis',      'yacute',         'thorn',          'ydieresis'
    ],
# Central Europe
    'ISO-8859-16' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'Aogonek',        'aogonek',        'Lslash',
        'Euro',           'quotedblbase',   'Scaron',         'section',
        'scaron',         'copyright',      'Scommaaccent',   'guillemotleft',
        'Zacute',         'hyphen',         'zacute',         'Zdotaccent',
        'degree',         'plusminus',      'Ccaron',         'lslash',
        'Zcaron',         'quotedblright',  'paragraph',      'periodcentered',
        'zcaron',         'ccaron',         'scommaaccent',   'guillemotright',
        'OE',             'oe',             'Ydieresis',      'zdotaccent',
        'Agrave',         'Aacute',         'Acircumflex',    'Abreve',
        'Adieresis',      'Cacute',         'AE',             'Ccedilla',
        'Egrave',         'Eacute',         'Ecircumflex',    'Edieresis',
        'Igrave',         'Iacute',         'Icircumflex',    'Idieresis',
        'Dcroat',         'Nacute',         'Ograve',         'Oacute',
        'Ocircumflex',    'Ohungarumlaut',  'Odieresis',      'Sacute',
        'Uhungarumlaut',  'Ugrave',         'Uacute',         'Ucircumflex',
        'Udieresis',      'Eogonek',        'Tcommaaccent',   'germandbls',
        'agrave',         'aacute',         'acircumflex',    'abreve',
        'adieresis',      'cacute',         'ae',             'ccedilla',
        'egrave',         'eacute',         'ecircumflex',    'edieresis',
        'igrave',         'iacute',         'icircumflex',    'idieresis',
        'dcroat',         'nacute',         'ograve',         'oacute',
        'ocircumflex',    'ohungarumlaut',  'odieresis',      'sacute',
        'uhungarumlaut',  'ugrave',         'uacute',         'ucircumflex',
        'udieresis',      'eogonek',        'tcommaaccent',   'ydieresis'
    ],
# Russian
    'KOI8-R' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'SF100000',       'SF110000',       'SF010000',       'SF030000',
        'SF020000',       'SF040000',       'SF080000',       'SF090000',
        'SF060000',       'SF070000',       'SF050000',       'upblock',
        'dnblock',        'block',          'lfblock',        'rtblock',
        'ltshade',        'shade',          'dkshade',        'integraltp',
        'filledbox',      'periodcentered', 'radical',        'approxequal',
        'lessequal',      'greaterequal',   'space',          'integralbt',
        'degree',         'twosuperior',    'periodcentered', 'divide',
        'SF430000',       'SF240000',       'SF510000',       'afii10071',
        'SF520000',       'SF390000',       'SF220000',       'SF210000',
        'SF250000',       'SF500000',       'SF490000',       'SF380000',
        'SF280000',       'SF270000',       'SF260000',       'SF360000',
        'SF370000',       'SF420000',       'SF190000',       'afii10023',
        'SF200000',       'SF230000',       'SF470000',       'SF480000',
        'SF410000',       'SF450000',       'SF460000',       'SF400000',
        'SF540000',       'SF530000',       'SF440000',       'copyright',
        'afii10096',      'afii10065',      'afii10066',      'afii10088',
        'afii10069',      'afii10070',      'afii10086',      'afii10068',
        'afii10087',      'afii10074',      'afii10075',      'afii10076',
        'afii10077',      'afii10078',      'afii10079',      'afii10080',
        'afii10081',      'afii10097',      'afii10082',      'afii10083',
        'afii10084',      'afii10085',      'afii10072',      'afii10067',
        'afii10094',      'afii10093',      'afii10073',      'afii10090',
        'afii10095',      'afii10091',      'afii10089',      'afii10092',
        'afii10048',      'afii10017',      'afii10018',      'afii10040',
        'afii10021',      'afii10022',      'afii10038',      'afii10020',
        'afii10039',      'afii10026',      'afii10027',      'afii10028',
        'afii10029',      'afii10030',      'afii10031',      'afii10032',
        'afii10033',      'afii10049',      'afii10034',      'afii10035',
        'afii10036',      'afii10037',      'afii10024',      'afii10019',
        'afii10046',      'afii10045',      'afii10025',      'afii10042',
        'afii10047',      'afii10043',      'afii10041',      'afii10044'
    ],
# Ukrainian
    'KOI8-U' => [
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        '.notdef',        '.notdef',        '.notdef',        '.notdef',
        'space',          'exclam',         'quotedbl',       'numbersign',
        'dollar',         'percent',        'ampersand',      'quotesingle',
        'parenleft',      'parenright',     'asterisk',       'plus',
        'comma',          'hyphen',         'period',         'slash',
        'zero',           'one',            'two',            'three',
        'four',           'five',           'six',            'seven',
        'eight',          'nine',           'colon',          'semicolon',
        'less',           'equal',          'greater',        'question',
        'at',             'A',              'B',              'C',
        'D',              'E',              'F',              'G',
        'H',              'I',              'J',              'K',
        'L',              'M',              'N',              'O',
        'P',              'Q',              'R',              'S',
        'T',              'U',              'V',              'W',
        'X',              'Y',              'Z',              'bracketleft',
        'backslash',      'bracketright',   'asciicircum',    'underscore',
        'grave',          'a',              'b',              'c',
        'd',              'e',              'f',              'g',
        'h',              'i',              'j',              'k',
        'l',              'm',              'n',              'o',
        'p',              'q',              'r',              's',
        't',              'u',              'v',              'w',
        'x',              'y',              'z',              'braceleft',
        'bar',            'braceright',     'asciitilde',     '.notdef',
        'SF100000',       'SF110000',       'SF010000',       'SF030000',
        'SF020000',       'SF040000',       'SF080000',       'SF090000',
        'SF060000',       'SF070000',       'SF050000',       'upblock',
        'dnblock',        'block',          'lfblock',        'rtblock',
        'ltshade',        'shade',          'dkshade',        'integraltp',
        'filledbox',      'bullet',         'radical',        'approxequal',
        'lessequal',      'greaterequal',   'space',          'integralbt',
        'degree',         'twosuperior',    'periodcentered', 'divide',
        'SF430000',       'SF240000',       'SF510000',       'afii10071',
        'afii10101',      'SF390000',       'afii10103',      'afii10104',
        'SF250000',       'SF500000',       'SF490000',       'SF380000',
        'SF280000',       'afii10098',      'SF260000',       'SF360000',
        'SF370000',       'SF420000',       'SF190000',       'afii10023',
        'afii10053',      'SF230000',       'afii10055',      'afii10056',
        'SF410000',       'SF450000',       'SF460000',       'SF400000',
        'SF540000',       'afii10050',      'SF440000',       'copyright',
        'afii10096',      'afii10065',      'afii10066',      'afii10088',
        'afii10069',      'afii10070',      'afii10086',      'afii10068',
        'afii10087',      'afii10074',      'afii10075',      'afii10076',
        'afii10077',      'afii10078',      'afii10079',      'afii10080',
        'afii10081',      'afii10097',      'afii10082',      'afii10083',
        'afii10084',      'afii10085',      'afii10072',      'afii10067',
        'afii10094',      'afii10093',      'afii10073',      'afii10090',
        'afii10095',      'afii10091',      'afii10089',      'afii10092',
        'afii10048',      'afii10017',      'afii10018',      'afii10040',
        'afii10021',      'afii10022',      'afii10038',      'afii10020',
        'afii10039',      'afii10026',      'afii10027',      'afii10028',
        'afii10029',      'afii10030',      'afii10031',      'afii10032',
        'afii10033',      'afii10049',      'afii10034',      'afii10035',
        'afii10036',      'afii10037',      'afii10024',      'afii10019',
        'afii10046',      'afii10045',      'afii10025',      'afii10042',
        'afii10047',      'afii10043',      'afii10041',      'afii10044'
    ]
}

def ReadAFM(file, map)

    # Read a font metric file
    a = IO.readlines(file)

    raise "File no found: #{file}" if a.size == 0

    widths = {}
    fm = {}
    fix = { 'Edot' => 'Edotaccent', 'edot' => 'edotaccent',
            'Idot' => 'Idotaccent',
            'Zdot' => 'Zdotaccent', 'zdot' => 'zdotaccent',
            'Odblacute' => 'Ohungarumlaut', 'odblacute' => 'ohungarumlaut',
            'Udblacute' => 'Uhungarumlaut', 'udblacute' => 'uhungarumlaut',
            'Gcedilla' => 'Gcommaaccent', 'gcedilla' => 'gcommaaccent',
            'Kcedilla' => 'Kcommaaccent', 'kcedilla' => 'kcommaaccent',
            'Lcedilla' => 'Lcommaaccent', 'lcedilla' => 'lcommaaccent',
            'Ncedilla' => 'Ncommaaccent', 'ncedilla' => 'ncommaaccent',
            'Rcedilla' => 'Rcommaaccent', 'rcedilla' => 'rcommaaccent',
            'Scedilla' => 'Scommaaccent',' scedilla' => 'scommaaccent',
            'Tcedilla' => 'Tcommaaccent',' tcedilla' => 'tcommaaccent',
            'Dslash' => 'Dcroat', 'dslash' => 'dcroat',
            'Dmacron' => 'Dcroat', 'dmacron' => 'dcroat',
            'combininggraveaccent' => 'gravecomb',
            'combininghookabove' => 'hookabovecomb',
            'combiningtildeaccent' => 'tildecomb',
            'combiningacuteaccent' => 'acutecomb',
            'combiningdotbelow' => 'dotbelowcomb',
            'dongsign' => 'dong'
        }

    a.each do |line|

        e = line.rstrip.split(' ')
  next if e.size < 2

  code  = e[0]
  param = e[1]

  if code == 'C' then

      # Character metrics
      cc = e[1].to_i
      w  = e[4]
      gn = e[7]

      gn = 'Euro' if gn[-4, 4] == '20AC'

      if fix[gn] then

    # Fix incorrect glyph name
    0.upto(map.size - 1) do |i|
        if map[i] == fix[gn] then
      map[i] = gn
        end
    end
      end

      if map.size == 0 then
    # Symbolic font: use built-in encoding
    widths[cc] = w
      else
    widths[gn] = w
    fm['CapXHeight'] = e[13].to_i if gn == 'X'
      end

      fm['MissingWidth'] = w if gn == '.notdef'

  elsif code == 'FontName' then
      fm['FontName'] = param
  elsif code == 'Weight' then
      fm['Weight'] = param
  elsif code == 'ItalicAngle' then
      fm['ItalicAngle'] = param.to_f
  elsif code == 'Ascender' then
      fm['Ascender'] = param.to_i
  elsif code == 'Descender' then
      fm['Descender'] = param.to_i
  elsif code == 'UnderlineThickness' then
      fm['UnderlineThickness'] = param.to_i
  elsif code == 'UnderlinePosition' then
      fm['UnderlinePosition'] = param.to_i
  elsif code == 'IsFixedPitch' then
      fm['IsFixedPitch'] = (param == 'true')
  elsif code == 'FontBBox' then
      fm['FontBBox'] = "[#{e[1]},#{e[2]},#{e[3]},#{e[4]}]"
  elsif code == 'CapHeight' then
      fm['CapHeight'] = param.to_i
  elsif code == 'StdVW' then
      fm['StdVW'] = param.to_i
  end
    end

    raise 'FontName not found' unless fm['FontName']

    if map.size > 0 then
  widths['.notdef'] = 600 unless widths['.notdef']

  if (widths['Delta'] == nil) && widths['increment'] then
      widths['Delta'] = widths['increment']
  end

  # Order widths according to map
  0.upto(255) do |i|
      if widths[map[i]] == nil
    puts "Warning: character #{map[i]} is missing"
    widths[i] = widths['.notdef']
      else
    widths[i] = widths[map[i]]
      end
  end
    end

    fm['Widths'] = widths

    return fm
end

def MakeFontDescriptor(fm, symbolic)

    # Ascent
    asc = fm['Ascender'] ? fm['Ascender'] : 1000
    fd = "{\n        'Ascent' => '#{asc}'"

    # Descent
    desc = fm['Descender'] ? fm['Descender'] : -200
    fd += ", 'Descent' => '#{desc}'"

    # CapHeight
    if fm['CapHeight'] then
        ch = fm['CapHeight']
    elsif fm['CapXHeight']
        ch = fm['CapXHeight']
    else
        ch = asc
    end
    fd += ", 'CapHeight' => '#{ch}'"

    # Flags
    flags = 0

    if fm['IsFixedPitch'] then
        flags += 1 << 0
    end

    if symbolic then
        flags += 1 << 2
    else
        flags += 1 << 5
    end

    if fm['ItalicAngle'] && (fm['ItalicAngle'] != 0) then
        flags += 1 << 6
    end

    fd += ",\n        'Flags' => '#{flags}'"

    # FontBBox
    if fm['FontBBox'] then
        fbb = fm['FontBBox'].gsub(/,/, ' ')
    else
        fbb = "[0 #{desc - 100} 1000 #{asc + 100}]"
    end

    fd += ", 'FontBBox' => '#{fbb}'"

    # ItalicAngle
    ia = fm['ItalicAngle'] ? fm['ItalicAngle'] : 0
    fd += ",\n        'ItalicAngle' => '#{ia}'"

    # StemV
    if fm['StdVW'] then
        stemv = fm['StdVW']
    elsif fm['Weight'] && (/bold|black/i =~ fm['Weight'])
        stemv = 120
    else
        stemv = 70
    end

    fd += ", 'StemV' => '#{stemv}'"

    # MissingWidth
    if fm['MissingWidth'] then
        fd += ", 'MissingWidth' => '#{fm['MissingWidth']}'"
    end

    fd += "\n        }"
    return fd
end

def MakeWidthArray(fm)

    # Make character width array
    s = "        [\n        "

    cw = fm['Widths']

    0.upto(255) do |i|
        s += "%5d" % cw[i]
        s += "," if i != 255
        s += "\n        " if (i % 8) == 7
    end

    s += ']'

    return s
end

def MakeFontEncoding(map)

    # Build differences from reference encoding
    ref = Charencodings['cp1252']
    s = ''
    last = 0
    32.upto(255) do |i|
  if map[i] != ref[i] then
      if i != last + 1 then
    s += i.to_s + ' '
            end
      last = i
      s += '/' + map[i] + ' '
  end
    end
    return s.rstrip
end

def ReadShort(f)
    a = f.read(2).unpack('n')
    return a[0]
end

def ReadLong(f)
    a = f.read(4).unpack('N')
    return a[0]
end

def CheckTTF(file)

    rl = false
    pp = false
    e  = false

    # Check if font license allows embedding
    File.open(file, 'rb') do |f|

        # Extract number of tables
        f.seek(4, IO::SEEK_CUR)
  nb = ReadShort(f)
        f.seek(6, IO::SEEK_CUR)

        # Seek OS/2 table
  found = false
        0.upto(nb - 1) do |i|
            if f.read(4) == 'OS/2' then
                found = true
                break
            end

           f.seek(12, IO::SEEK_CUR)
        end

  if ! found then
            return
        end

        f.seek(4, IO::SEEK_CUR)
        offset = ReadLong(f)
        f.seek(offset, IO::SEEK_SET)

        # Extract fsType flags
        f.seek(8, IO::SEEK_CUR)
  fsType = ReadShort(f)

  rl = (fsType & 0x02) != 0
  pp = (fsType & 0x04) != 0
  e  = (fsType & 0x08) != 0
    end

    if rl && ( ! pp) && ( ! e) then
        puts 'Warning: font license does not allow embedding'
    end
end

#
# fontfile: path to TTF file (or empty string if not to be embedded)
# afmfile:  path to AFM file
# enc:      font encoding (or empty string for symbolic fonts)
# patch:    optional patch for encoding
# type :    font type if $fontfile is empty
#
def MakeFont(fontfile, afmfile, enc = 'cp1252', patch = {}, type = 'TrueType')
    # Generate a font definition file
    if (enc != nil) && (enc != '') then
  map = Charencodings[enc]
  patch.each { |cc, gn| map[cc] = gn }
    else
  map = []
    end

    raise "Error: AFM file not found: #{afmfile}" unless File.exists?(afmfile)

    fm = ReadAFM(afmfile, map)

    if (enc != nil) && (enc != '') then
  diff = MakeFontEncoding(map)
    else
  diff = ''
    end

    fd = MakeFontDescriptor(fm, (map.size == 0))

    # Find font type
    if fontfile then
        ext = File.extname(fontfile).downcase.sub(/\A\./, '')

        if ext == 'ttf' then
            type = 'TrueType'
        elsif ext == 'pfb'
            type = 'Type1'
        else
            raise "Error: unrecognized font file extension: #{ext}"
        end
    else
      raise "Error: incorrect font type: #{type}" if (type != 'TrueType') && (type != 'Type1')
    end
    printf "type = #{type}\n"
    # Start generation
    s  = "# #{fm['FontName']} font definition\n\n"
    s += "module FontDef\n"
    s += "    def FontDef.type\n        '#{type}'\n    end\n"
    s += "    def FontDef.name\n        '#{fm['FontName']}'\n    end\n"
    s += "    def FontDef.desc\n        #{fd}\n    end\n"

    if fm['UnderlinePosition'] == nil then
        fm['UnderlinePosition'] = -100
    end

    if fm['UnderlineThickness'] == nil then
        fm['UnderlineThickness'] = 50
    end

    s += "    def FontDef.up\n        #{fm['UnderlinePosition']}\n    end\n"
    s += "    def FontDef.ut\n        #{fm['UnderlineThickness']}\n    end\n"

    w = MakeWidthArray(fm)
    s += "    def FontDef.cw\n#{w}\n    end\n"

    s += "    def FontDef.enc\n        '#{enc}'\n    end\n"
    s += "    def FontDef.diff\n        #{(diff == nil) || (diff == '') ? 'nil' : '\'' + diff '\''}\n    end\n"

    basename = File.basename(afmfile, '.*')

    if fontfile then
        # Embedded font
        if ! File.exist?(fontfile) then
            raise "Error: font file not found: #{fontfile}"
        end

        if type == 'TrueType' then
            CheckTTF(fontfile)
        end

  file = ''
        File.open(fontfile, 'rb') do |f|
            file = f.read()
        end

        if type == 'Type1' then
            # Find first two sections and discard third one
            header = file[0] == 128
            file = file[6, file.length - 6] if header

            pos = file.index('eexec')
            raise 'Error: font file does not seem to be valid Type1' if pos == nil

            size1 = pos + 6

            file = file[0, size1] + file[size1 + 6, file.length - (size1 + 6)] if header && file[size1] == 128

            pos = file.index('00000000')
            raise 'Error: font file does not seem to be valid Type1' if pos == nil

            size2 = pos - size1
            file = file[0, size1 + size2]
        end

        if require 'zlib' then
            File.open(basename + '.z', 'wb') { |f| f.write(Zlib::Deflate.deflate(file)) }
            s += "    def FontDef.file\n        '#{basename}.z'\n    end\n"
            puts "Font file compressed ('#{basename}.z')"
        else
            s += "    def FontDef.file\n        '#{File.basename(fontfile)}'\n    end\n"
            puts 'Notice: font file could not be compressed (zlib not available)'
        end

        if type == 'Type1' then
            s += "    def FontDef.size1\n        '#{size1}'\n    end\n"
            s += "    def FontDef.size2\n        '#{size2}'\n    end\n"
        else
            s += "    def FontDef.originalsize\n        '#{File.size(fontfile)}'\n    end\n"
        end

    else
        # Not embedded font
        s += "    def FontDef.file\n        ''\n    end\n"
    end

    s += "end\n"
    File.open(basename + '.rb', 'w') { |file| file.write(s)}
    puts "Font definition file generated (#{basename}.rb)"
end


if $0 == __FILE__ then
    if ARGV.length >= 3 then
        enc = ARGV[2]
    else
        enc = 'cp1252'
    end

    if ARGV.length >= 4 then
        patch = ARGV[3]
    else
        patch = {}
    end

    if ARGV.length >= 5 then
        type = ARGV[4]
    else
        type = 'TrueType'
    end

    MakeFont(ARGV[0], ARGV[1], enc, patch, type)
end
