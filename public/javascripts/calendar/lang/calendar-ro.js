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
("Duminica",
 "Luni",
 "Marti",
 "Miercuri",
 "Joi",
 "Vineri",
 "Sambata",
 "Duminica");

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
("Dum",
 "Lun",
 "Mar",
 "Mie",
 "Joi",
 "Vin",
 "Sam",
 "Dum");

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 0;

// full month names
Calendar._MN = new Array
("Ianuarie",
 "Februarie",
 "Martie",
 "Aprilie",
 "Mai",
 "Iunie",
 "Iulie",
 "August",
 "Septembrie",
 "Octombrie",
 "Noiembrie",
 "Decembrie");

// short month names
Calendar._SMN = new Array
("Ian",
 "Feb",
 "Mar",
 "Apr",
 "Mai",
 "Iun",
 "Iul",
 "Aug",
 "Sep",
 "Oct",
 "Noi",
 "Dec");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Despre calendar";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Selectare data:\n" +
"- Folositi butoanele \xab, \xbb pentru a selecta anul\n" +
"- Folositi butoanele " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " pentru a selecta luna\n" +
"- Lasati apasat butonul pentru o selectie mai rapida.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Selectare timp:\n" +
"- Click pe campul de timp pentru a majora timpul\n" +
"- sau Shift-Click pentru a micsora\n" +
"- sau click si drag pentru manipulare rapida.";

Calendar._TT["PREV_YEAR"] = "Anul precedent (apasati pentru meniu)";
Calendar._TT["PREV_MONTH"] = "Luna precedenta (apasati pentru meniu)";
Calendar._TT["GO_TODAY"] = "Data de azi";
Calendar._TT["NEXT_MONTH"] = "Luna viitoare (apasati pentru meniu)";
Calendar._TT["NEXT_YEAR"] = "Anul viitor (apasati pentru meniu)";
Calendar._TT["SEL_DATE"] = "Selectie data";
Calendar._TT["DRAG_TO_MOVE"] = "Drag pentru a muta";
Calendar._TT["PART_TODAY"] = " (azi)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Vizualizeaza %s prima";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "inchide";
Calendar._TT["TODAY"] = "Azi";
Calendar._TT["TIME_PART"] = "(Shift-)Click sau drag pentru a schimba valoarea";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%A-%l-%z";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "sapt";
Calendar._TT["TIME"] = "Ora:";
