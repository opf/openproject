module CodeRay
  class Tokens
    ClassOfKind = Hash.new do |h, k|
      h[k] = k.to_s
    end
    ClassOfKind.update with = {
      :annotation => 'at',
      :attribute_name => 'an',
      :attribute_name_fat => 'af',
      :attribute_value => 'av',
      :attribute_value_fat => 'aw',
      :bin => 'bi',
      :char => 'ch',
      :class => 'cl',
      :class_variable => 'cv',
      :color => 'cr',
      :comment => 'c',
      :complex => 'cm',
      :constant => 'co',
      :content => 'k',
      :decorator => 'de',
      :definition => 'df',
      :delimiter => 'dl',
      :directive => 'di',
      :doc => 'do',
      :doctype => 'dt',
      :doc_string => 'ds',
      :entity => 'en',
      :error => 'er',
      :escape => 'e',
      :exception => 'ex',
      :float => 'fl',
      :function => 'fu',
      :global_variable => 'gv',
      :hex => 'hx',
      :imaginary => 'cm',
      :important => 'im',
      :include => 'ic',
      :inline => 'il',
      :inline_delimiter => 'idl',
      :instance_variable => 'iv',
      :integer => 'i',
      :interpreted => 'in',
      :keyword => 'kw',
      :key => 'ke',
      :label => 'la',
      :local_variable => 'lv',
      :modifier => 'mod',
      :oct => 'oc',
      :operator_fat => 'of',
      :pre_constant => 'pc',
      :pre_type => 'pt',
      :predefined => 'pd',
      :preprocessor => 'pp',
      :pseudo_class => 'ps',
      :regexp => 'rx',
      :reserved => 'r',
      :shell => 'sh',
      :string => 's',
      :symbol => 'sy',
      :tag => 'ta',
      :tag_fat => 'tf',
      :tag_special => 'ts',
      :type => 'ty',
      :variable => 'v',
      :value => 'vl',
      :xml_text => 'xt',
      
      :insert => 'ins',
      :delete => 'del',
      :change => 'chg',
      :head => 'head',

      :ident => :NO_HIGHLIGHT, # 'id'
      #:operator => 'op',
      :operator => :NO_HIGHLIGHT,  # 'op'
      :space => :NO_HIGHLIGHT,  # 'sp'
      :plain => :NO_HIGHLIGHT,
    }
    ClassOfKind[:method] = ClassOfKind[:function]
    ClassOfKind[:open] = ClassOfKind[:close] = ClassOfKind[:delimiter]
    ClassOfKind[:nesting_delimiter] = ClassOfKind[:delimiter]
    ClassOfKind[:escape] = ClassOfKind[:delimiter]
    #ClassOfKind.default = ClassOfKind[:error] or raise 'no class found for :error!'
  end
end