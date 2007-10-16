// ** I18N

// Calendar HE language
// Author: Saggi Mizrahi
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("ראשון",
 "שני",
 "שלישי",
 "רביעי",
 "חמישי",
 "שישי",
 "שבת",
 "ראשון");

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
("א",
 "ב",
 "ג",
 "ד",
 "ה",
 "ו",
 "ש",
 "א");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 0;

// full month names
Calendar._MN = new Array
("ינואר",
 "פברואר",
 "מרץ",
 "אפריל",
 "מאי",
 "יוני",
 "יולי",
 "אוגוסט",
 "ספטמבר",
 "אוקטובר",
 "נובמבר",
 "דצמבר");

// short month names
Calendar._SMN = new Array
("ינו'",
 "פבו'",
 "מרץ",
 "אפר'",
 "מאי",
 "יונ'",
 "יול'",
 "אוג'",
 "ספט'",
 "אוקט'",
 "נוב'",
 "דצמ'");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "אודות לוח השנה";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Date selection:\n" +
"- Use the \xab, \xbb buttons to select year\n" +
"- Use the " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " buttons to select month\n" +
"- Hold mouse button on any of the above buttons for faster selection.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Time selection:\n" +
"- Click on any of the time parts to increase it\n" +
"- or Shift-click to decrease it\n" +
"- or click and drag for faster selection.";

Calendar._TT["PREV_YEAR"] = "שנה קודמת (החזק לתפריט)";
Calendar._TT["PREV_MONTH"] = "חודש קודם (החזק לתפריט)";
Calendar._TT["GO_TODAY"] = "לך להיום";
Calendar._TT["NEXT_MONTH"] = "חודש הבא (החזק לתפריט)";
Calendar._TT["NEXT_YEAR"] = "שנה הבאה (החזק לתפריט)";
Calendar._TT["SEL_DATE"] = "בחר תאריך";
Calendar._TT["DRAG_TO_MOVE"] = "משוך כדי להזיז";
Calendar._TT["PART_TODAY"] = " (היום)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "הצג %s קודם";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "6,7";

Calendar._TT["CLOSE"] = "סגור";
Calendar._TT["TODAY"] = "היום";
Calendar._TT["TIME_PART"] = "(Shift-)לחץ או משוך כדי לשנות את הערך";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d-%m-%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "זמן:";
