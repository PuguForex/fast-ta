/**
 * @file Source - Unified data transfer structure wrapping raw indicator calculations or standard OHLCV candle metrics.
 * @deps None (Pure architectural structural definition)
 * @state Pure (Stateless data container initialized cleanly via static factory methods)
 * @io   Raw value or explicit OHLC components -> Instantiates unified Source struct container
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __SOURCE_MQH__
#define __SOURCE_MQH__

struct Source
{
   double   value;
   double   open;
   double   high;
   double   low;
   double   close;
   datetime time;

   static Source From(const double value_, const datetime time_)
   {
      Source s;
      s.value = value_;
      s.open  = value_;
      s.high  = value_;
      s.low   = value_;
      s.close = value_;
      s.time  = time_;
      return(s);
   }

   static Source From(
      const double open_,
      const double high_,
      const double low_,
      const double close_,
      const datetime time_)
   {
      Source s;
      s.value = close_;
      s.open  = open_;
      s.high  = high_;
      s.low   = low_;
      s.close = close_;
      s.time  = time_;
      return(s);
   }
};

#endif // __SOURCE_MQH__
//+------------------------------------------------------------------+