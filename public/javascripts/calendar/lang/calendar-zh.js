// ** I18N

// Calendar Chinese language
// Author: Andy Wu, <andywu.zh@gmail.com>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("星期日",
 "星期一",
 "星期二",
 "星期三",
 "星期四",
 "星期五",
 "星期六",
 "星期日");

// Please note that the following array of short day names (and the same goes
// for short month names, _SMN) isn't absolutely necessary.  We give it here
// for exemplification on how one can customize the short day names, but if
// they are simply the first N letters of the full name you can simply say:
//
//   Calendar._SDN_len = N; // short day name length
//   Calendar._SMN_len = N; // short month name length
//
// If N = 3 then this is not needed either since we assume a value of 3 if not
// present, to be compatible with translation files that were written before
// this feature.

// short day names
Calendar._SDN = new Array
("日",
 "一",
 "二",
 "三",
 "四",
 "五",
 "六",
 "日");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 0;

// full month names
Calendar._MN = new Array
("1月",
 "2月",
 "3月",
 "4月",
 "5月",
 "6月",
 "7月",
 "8月",
 "9月",
 "10月",
 "11月",
 "12月");

// short month names
Calendar._SMN = new Array
("1月",
 "2月",
 "3月",
 "4月",
 "5月",
 "6月",
 "7月",
 "8月",
 "9月",
 "10月",
 "11月",
 "12月");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "关于日历";

Calendar._TT["ABOUT"] =
"DHTML 日期/时间 选择器\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"最新版本请访问： http://www.dynarch.com/projects/calendar/\n" +
"遵循 GNU LGPL 发布。详情请查阅 http://gnu.org/licenses/lgpl.html " +
"\n\n" +
"日期选择：\n" +
"- 使用 \xab，\xbb 按钮选择年\n" +
"- 使用 " + String.fromCharCode(0x2039) + "，" + String.fromCharCode(0x203a) + " 按钮选择月\n" +
"- 在上述按钮上按住不放可以快速选择";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"时间选择：\n" +
"- 点击时间的任意部分来增加\n" +
"- Shift加点击来减少\n" +
"- 点击后拖动进行快速选择";

Calendar._TT["PREV_YEAR"] = "上年（按住不放显示菜单）";
Calendar._TT["PREV_MONTH"] = "上月（按住不放显示菜单）";
Calendar._TT["GO_TODAY"] = "回到今天";
Calendar._TT["NEXT_MONTH"] = "下月（按住不放显示菜单）";
Calendar._TT["NEXT_YEAR"] = "下年（按住不放显示菜单）";
Calendar._TT["SEL_DATE"] = "选择日期";
Calendar._TT["DRAG_TO_MOVE"] = "拖动";
Calendar._TT["PART_TODAY"] = " (今日)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "一周开始于 %s";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "关闭";
Calendar._TT["TODAY"] = "今天";
Calendar._TT["TIME_PART"] = "Shift加点击或者拖动来变更";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "星期%a %b%e日";

Calendar._TT["WK"] = "周";
Calendar._TT["TIME"] = "时间：";
