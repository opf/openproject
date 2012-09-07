// ** I18N

// full day names
Calendar._DN = new Array
("Söndag",
 "Måndag",
 "Tisdag",
 "Onsdag",
 "Torsdag",
 "Fredag",
 "Lördag",
 "Söndag");

Calendar._SDN_len = 3; // short day name length
Calendar._SMN_len = 3; // short month name length


// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// full month names
Calendar._MN = new Array
("Januari",
 "Februari",
 "Mars",
 "April",
 "Maj",
 "Juni",
 "Juli",
 "Augusti",
 "September",
 "Oktober",
 "November",
 "December");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Om kalendern";

Calendar._TT["ABOUT"] =
"DHTML Datum/Tid-väljare\n" +
"(c) dynarch.com 2002-2005 / Upphovsman: Mihai Bazon\n" + // don't translate this this ;-)
"För senaste version besök: http://www.dynarch.com/projects/calendar/\n" +
"Distribueras under GNU LGPL.  Se http://gnu.org/licenses/lgpl.html för detaljer." +
"\n\n" +
"Välja datum:\n" +
"- Använd \xab, \xbb knapparna för att välja år\n" +
"- Använd " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " knapparna för att välja månad\n" +
"- Håll nere musknappen på någon av ovanstående knappar för att se snabbval.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Välja tid:\n" +
"- Klicka på något av tidsfälten för att öka\n" +
"- eller Skift-klicka för att minska\n" +
"- eller klicka och dra för att välja snabbare.";

Calendar._TT["PREV_YEAR"] = "Föreg. år (håll nere för lista)";
Calendar._TT["PREV_MONTH"] = "Föreg. månad (håll nere för lista)";
Calendar._TT["GO_TODAY"] = "Gå till Idag";
Calendar._TT["NEXT_MONTH"] = "Nästa månad (håll nere för lista)";
Calendar._TT["NEXT_YEAR"] = "Nästa år (håll nere för lista)";
Calendar._TT["SEL_DATE"] = "Välj datum";
Calendar._TT["DRAG_TO_MOVE"] = "Dra för att flytta";
Calendar._TT["PART_TODAY"] = " (idag)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Visa %s först";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Stäng";
Calendar._TT["TODAY"] = "Idag";
Calendar._TT["TIME_PART"] = "(Skift-)klicka eller dra för att ändra värde";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "v.";
Calendar._TT["TIME"] = "Tid:";
