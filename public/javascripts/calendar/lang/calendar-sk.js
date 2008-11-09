/* 
	calendar-sk.js
	language: Slovak
	encoding: UTF-8
	author: Stanislav Pach (stano.pach@seznam.cz)
*/

// ** I18N
Calendar._DN  = new Array('Nedeľa','Pondelok','Utorok','Streda','Štvrtok','Piatok','Sobota','Nedeľa');
Calendar._SDN = new Array('Ne','Po','Ut','St','Št','Pi','So','Ne');
Calendar._MN  = new Array('Január','Február','Marec','Apríl','Máj','Jún','Júl','August','September','Október','November','December');
Calendar._SMN = new Array('Jan','Feb','Mar','Apr','Máj','Jún','Júl','Aug','Sep','Okt','Nov','Dec');

// First day of the week. "0" means display Sunday first, "1" means display
// Monday first, etc.
Calendar._FD = 1;

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "O komponente kalendár";
Calendar._TT["TOGGLE"] = "Zmena prvého dňa v týždni";
Calendar._TT["PREV_YEAR"] = "Predchádzajúci rok (pridrž pre menu)";
Calendar._TT["PREV_MONTH"] = "Predchádzajúci mesiac (pridrž pre menu)";
Calendar._TT["GO_TODAY"] = "Dnešný dátum";
Calendar._TT["NEXT_MONTH"] = "Ďalší mesiac (pridrž pre menu)";
Calendar._TT["NEXT_YEAR"] = "Ďalší rok (pridrž pre menu)";
Calendar._TT["SEL_DATE"] = "Zvoľ dátum";
Calendar._TT["DRAG_TO_MOVE"] = "Chyť a ťahaj pre presun";
Calendar._TT["PART_TODAY"] = " (dnes)";
Calendar._TT["MON_FIRST"] = "Ukáž ako prvný Pondelok";
//Calendar._TT["SUN_FIRST"] = "Ukaž jako první Neděli";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Výber dátumu:\n" +
"- Použijte tlačítka \xab, \xbb pre voľbu roku\n" +
"- Použijte tlačítka " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " pre výber mesiaca\n" +
"- Podržte tlačítko myši na akomkoľvek z týchto tlačítok pre rýchlejší výber.";

Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Výber času:\n" +
"- Kliknite na akúkoľvek časť z výberu času pre zvýšenie.\n" +
"- alebo Shift-klick pre zníženie\n" +
"- alebo kliknite a ťahajte pre rýchlejší výber.";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Zobraz %s ako prvý";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Zavrieť";
Calendar._TT["TODAY"] = "Dnes";
Calendar._TT["TIME_PART"] = "(Shift-)Klikni alebo ťahaj pre zmenu hodnoty";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "d.m.yy";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "týž";
Calendar._TT["TIME"] = "Čas:";
