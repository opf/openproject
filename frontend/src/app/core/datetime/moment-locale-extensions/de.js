export default {
  relativeTime: {
    future : 'in %s',
    past : 'vor %s',
    s  : function (number, withoutSuffix) {
      return withoutSuffix ? 'jetzt' : 'ein paar Sekunden';
    },
    m  : '1min',
    mm : '%dmin',
    h  : '1Std',
    hh : '%dStd',
    d  : '1T',
    dd : '%dT',
    M  : '1M',
    MM : '%dM',
    y  : '1J',
    yy : '%dJ'
  }
};
