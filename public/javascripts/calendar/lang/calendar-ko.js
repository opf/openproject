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
("일요일",
 "월요일",
 "화요일",
 "수요일",
 "목요일",
 "금요일",
 "토요일",
 "일요일");

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
("일",
 "월",
 "화",
 "수",
 "목",
 "금",
 "토",
 "일");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 0;

// full month names
Calendar._MN = new Array
("1월",
 "2월",
 "3월",
 "4월",
 "5월",
 "6월",
 "7월",
 "8월",
 "9월",
 "10월",
 "11월",
 "12월");

// short month names
Calendar._SMN = new Array
("1월",
 "2월",
 "3월",
 "4월",
 "5월",
 "6월",
 "7월",
 "8월",
 "9월",
 "10월",
 "11월",
 "12월");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "이 달력은 ... & 도움말";

Calendar._TT["ABOUT"] =
"DHTML 날짜/시간 선택기\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"최신 버전을 구하려면 여기로: http://www.dynarch.com/projects/calendar/\n" +
"배포라이센스:GNU LGPL.  참조:http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"날짜 선택:\n" +
"- 해를 선택하려면 \xab, \xbb 버튼을 사용하세요.\n" +
"- 달을 선택하려면 " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " 버튼을 사용하세요.\n" +
"- 좀 더 빠르게 선택하려면 위의 버튼을 꾹 눌러주세요.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"시간 선택:\n" +
"- 시, 분을 더하려면 클릭하세요.\n" +
"- 시, 분을 빼려면  쉬프트 누르고 클릭하세요.\n" +
"- 좀 더 빠르게 선택하려면 클릭하고 드래그하세요.";

Calendar._TT["PREV_YEAR"] = "이전 해";
Calendar._TT["PREV_MONTH"] = "이전 달";
Calendar._TT["GO_TODAY"] = "오늘로 이동";
Calendar._TT["NEXT_MONTH"] = "다음 달";
Calendar._TT["NEXT_YEAR"] = "다음 해";
Calendar._TT["SEL_DATE"] = "날짜 선택";
Calendar._TT["DRAG_TO_MOVE"] = "이동(드래그)";
Calendar._TT["PART_TODAY"] = " (오늘)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "[%s]을 처음으로";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "닫기";
Calendar._TT["TODAY"] = "오늘";
Calendar._TT["TIME_PART"] = "클릭(+),쉬프트+클릭(-),드래그";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "주";
Calendar._TT["TIME"] = "시간:";
