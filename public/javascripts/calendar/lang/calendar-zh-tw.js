// ** I18N

// Calendar EN language
// Author: Mihai Bazon, <mihai_bazon@yahoo.com>
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
("一月",
 "二月",
 "三月",
 "四月",
 "五月",
 "六月",
 "七月",
 "八月",
 "九月",
 "十月",
 "十一月",
 "十二月");

// short month names
Calendar._SMN = new Array
("一月",
 "二月",
 "三月",
 "四月",
 "五月",
 "六月",
 "七月",
 "八月",
 "九月",
 "十月",
 "十一月",
 "十二月");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "關於 calendar";

Calendar._TT["ABOUT"] =
"DHTML 日期/時間 選擇器\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"最For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Date selection:\n" +
"- Use the \xab, \xbb buttons to select year\n" +
"- Use the " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " buttons to select month\n" +
"- Hold mouse button on any of the above buttons for faster selection.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"時間選擇方式：\n" +
"- 「單擊」時分秒為遞增\n" +
"- 或 「Shift-單擊」為遞減\n" +
"- 或 「單擊且拖拉」為快速選擇";

Calendar._TT["PREV_YEAR"] = "前一年 (按住不放可顯示選單)";
Calendar._TT["PREV_MONTH"] = "前一個月 (按住不放可顯示選單)";
Calendar._TT["GO_TODAY"] = "選擇今天";
Calendar._TT["NEXT_MONTH"] = "後一個月 (按住不放可顯示選單)";
Calendar._TT["NEXT_YEAR"] = "下一年 (按住不放可顯式選單)";
Calendar._TT["SEL_DATE"] = "請點選日期";
Calendar._TT["DRAG_TO_MOVE"] = "按住不放可拖拉視窗";
Calendar._TT["PART_TODAY"] = " (今天)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "以 %s 做為一週的首日";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "關閉視窗";
Calendar._TT["TODAY"] = "今天";
Calendar._TT["TIME_PART"] = "(Shift-)加「單擊」或「拖拉」可變更值";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "星期 %a, %b %e 日";

Calendar._TT["WK"] = "週";
Calendar._TT["TIME"] = "時間:";
