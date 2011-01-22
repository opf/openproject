module CodeRay
module Styles

  class Murphy < Style

    register_for :murphy

    code_background = '#001129'
    numbers_background = code_background
    border_color = 'silver'
    normal_color = '#C0C0C0'

    CSS_MAIN_STYLES = <<-MAIN
.CodeRay {
  background-color: #{code_background};
  border: 1px solid #{border_color};
  font-family: 'Courier New', 'Terminal', monospace;
  color: #{normal_color};
}
.CodeRay pre { margin: 0px; }

div.CodeRay { }

span.CodeRay { white-space: pre; border: 0px; padding: 2px; }

table.CodeRay { border-collapse: collapse; width: 100%; padding: 2px; }
table.CodeRay td { padding: 2px 4px; vertical-align: top; }

.CodeRay .line_numbers, .CodeRay .no {
  background-color: #{numbers_background};
  color: gray;
  text-align: right;
}
.CodeRay .line_numbers tt { font-weight: bold; }
.CodeRay .line_numbers .highlighted { color: red }
.CodeRay .line { display: block; float: left; width: 100%; }
.CodeRay .no { padding: 0px 4px; }
.CodeRay .code { width: 100%; }

ol.CodeRay { font-size: 10pt; }
ol.CodeRay li { white-space: pre; }

.CodeRay .code pre { overflow: auto; }
    MAIN

    TOKEN_COLORS = <<-'TOKENS'
.af { color:#00C; }
.an { color:#007; }
.av { color:#700; }
.aw { color:#C00; }
.bi { color:#509; font-weight:bold; }
.c  { color:#555; background-color: black; }

.ch { color:#88F; }
.ch .k { color:#04D; }
.ch .dl { color:#039; }

.cl { color:#e9e; font-weight:bold; }
.co { color:#5ED; font-weight:bold; }
.cr { color:#0A0; }
.cv { color:#ccf; }
.df { color:#099; font-weight:bold; }
.di { color:#088; font-weight:bold; }
.dl { color:black; }
.do { color:#970; }
.ds { color:#D42; font-weight:bold; }
.e  { color:#666; font-weight:bold; }
.er { color:#F00; background-color:#FAA; }
.ex { color:#F00; font-weight:bold; }
.fl { color:#60E; font-weight:bold; }
.fu { color:#5ed; font-weight:bold; }
.gv { color:#f84; }
.hx { color:#058; font-weight:bold; }
.i  { color:#66f; font-weight:bold; }
.ic { color:#B44; font-weight:bold; }
.il { }
.in { color:#B2B; font-weight:bold; }
.iv { color:#aaf; }
.la { color:#970; font-weight:bold; }
.lv { color:#963; }
.oc { color:#40E; font-weight:bold; }
.of { color:#000; font-weight:bold; }
.op { }
.pc { color:#08f; font-weight:bold; }
.pd { color:#369; font-weight:bold; }
.pp { color:#579; }
.pt { color:#66f; font-weight:bold; }
.r  { color:#5de; font-weight:bold; }
.r, .kw  { color:#5de; font-weight:bold }

.ke { color: #808; }

.rx { background-color:#221133; }
.rx .k { color:#f8f; }
.rx .dl { color:#f0f; }
.rx .mod { color:#f0b; }
.rx .fu  { color:#404; font-weight: bold; }

.s  { background-color:#331122; }
.s  .s { background-color:#ffe0e0; }
.s  .s  .s { background-color:#ffd0d0; }
.s  .k { color:#F88; }
.s  .dl { color:#f55; }

.sh { background-color:#f0fff0; }
.sh .k { color:#2B2; }
.sh .dl { color:#161; }

.sy { color:#Fc8; }
.sy .k { color:#Fc8; }
.sy .dl { color:#F84; }

.ta { color:#070; }
.tf { color:#070; font-weight:bold; }
.ts { color:#D70; font-weight:bold; }
.ty { color:#339; font-weight:bold; }
.v  { color:#036; }
.xt { color:#444; }

.ins { background: #afa; }
.del { background: #faa; }
.chg { color: #aaf; background: #007; }
.head { color: #f8f; background: #505 }

.ins .ins { color: #080; font-weight:bold }
.del .del { color: #800; font-weight:bold }
.chg .chg { color: #66f; }
.head .head { color: #f4f; }
    TOKENS

  end

end
end
