// ** I18N

// Calendar NO language (Norwegian/Norsk bokmål)
// Author: Kai Olav Fredriksen <k@i.fredriksen.net>

// full day names
Calendar._DN = new Array
("Søndag",
 "Mandag",
 "Tirsdag",
 "Onsdag",
 "Torsdag",
 "Fredag",
 "Lørdag",
 "Søndag");

Calendar._SDN_len = 3; // short day name length
Calendar._SMN_len = 3; // short month name length

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Januar",
 "Februar",
 "Mars",
 "April",
 "Mai",
 "Juni",
 "Juli",
 "August",
 "September",
 "Oktober",
 "November",
 "Desember");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Om kalenderen";

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

Calendar._TT["PREV_YEAR"] = "Forrige år (hold for meny)";
Calendar._TT["PREV_MONTH"] = "Forrige måned (hold for meny)";
Calendar._TT["GO_TODAY"] = "Gå til idag";
Calendar._TT["NEXT_MONTH"] = "Neste måned (hold for meny)";
Calendar._TT["NEXT_YEAR"] = "Neste år (hold for meny)";
Calendar._TT["SEL_DATE"] = "Velg dato";
Calendar._TT["DRAG_TO_MOVE"] = "Dra for å flytte";
Calendar._TT["PART_TODAY"] = " (idag)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Vis %s først";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Lukk";
Calendar._TT["TODAY"] = "Idag";
Calendar._TT["TIME_PART"] = "(Shift-)Klikk eller dra for å endre verdi";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%%d.%m.%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "uke";
Calendar._TT["TIME"] = "Tid:";
