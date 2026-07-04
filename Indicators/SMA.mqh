/**
 * @file SMA - Concrete Streaming Simple Moving Average indicator using synchronized time-series events and rolling sums.
 * @deps IndicatorBase.mqh, BarSeriesBuffer.mqh, RollingSum.mqh
 * @state Stateful (Orchestrates time-series buffers and internal rolling arithmetic accumulators across ticks)
 * @io   Source struct pricing tick -> Updates rolling sum and underlying time buffers | Request offset index -> Returns historical SMA double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __SMA_MQH__
#define __SMA_MQH__

#include "IndicatorBase.mqh"
#include "..\\Storage\\BarSeriesBuffer.mqh"
#include "..\\Algorithms\\RollingSum.mqh"

//+------------------------------------------------------------------+
//| SMA                                                              |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Streaming Simple Moving Average indicator.                       |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Maintain SMA configuration                                     |
//| • Orchestrate input series, events, and rolling sum              |
//| • Calculate SMA values                                           |
//| • Persist calculated output                                      |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Circular storage implementation                                |
//| • Rolling sum implementation                                     |
//| • MT5 lifecycle management                                       |
//+------------------------------------------------------------------+
class SMA : public IndicatorBase
{
private:

   int                m_period;
   CBarSeriesBuffer   m_input;
   CRollingSum        m_rollingSum;
   CBarSeriesBuffer   m_main;

public:

   static const int MAIN;

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   SMA()
   {
      m_period = 0;
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                       |
   //+------------------------------------------------------------------+
   ~SMA()
   {
   }

   //+------------------------------------------------------------------+
   //| Parameters                                                       |
   //+------------------------------------------------------------------+
   void SetParameters(const int period)
   {
      m_period = period;
   }

   //+------------------------------------------------------------------+
   //| Initialize                                                       |
   //+------------------------------------------------------------------+
   virtual bool Init()
   {
      if(m_period <= 0)
         return(false);

      if(m_maxBarsBack == 0)
         m_maxBarsBack = m_period;

      if(m_maxBarsBack <= 0)
         return(false);

      if(!m_input.Init(m_period))
         return(false);

      if(!m_main.Init(m_maxBarsBack))
         return(false);

      m_rollingSum.Reset();

      return(true);
   }

   virtual void Reset()
   {
      m_input.Reset();
      m_rollingSum.Reset();
      m_main.Reset();
   }

   //+------------------------------------------------------------------+
   //| Deinitialize                                                     |
   //+------------------------------------------------------------------+
   virtual void DeInit()
   {
      Reset();
   }

   //+------------------------------------------------------------------+
   //| Update                                                           |
   //+------------------------------------------------------------------+
   virtual void Update(const Source &src)
   {
      ESeriesEvent event = m_input.Update(src.time, src.value);
      double dropped = m_input.DroppedValue();

      switch(event)
      {
      case SERIES_FIRST_SAMPLE:
         m_rollingSum.RollOver();
         m_rollingSum.Update(src.value, 0.0);
         break;

      case SERIES_APPEND:
         m_rollingSum.RollOver();
         m_rollingSum.Update(src.value, dropped);
         break;

      case SERIES_REPLACE_LAST:
         m_rollingSum.RollBack();
         m_rollingSum.Update(src.value, dropped);
         break;

      case SERIES_RESET:
         m_rollingSum.Reset();
         m_rollingSum.RollOver();
         m_rollingSum.Update(src.value, 0.0);
         break;
      }

      double result = m_errorValue;

      if(m_input.IsFull())
         result = m_rollingSum.Value() / m_period;

      m_main.Update(src.time, result);
   }

   //+------------------------------------------------------------------+
   //| Value Access                                                     |
   //+------------------------------------------------------------------+
   virtual double GetValue(const int index,
                           const int lineIndex = 0)
   {
      if(lineIndex != MAIN)
         return(m_errorValue);

      double value;

      if(!m_main.At(index, value))
         return(m_errorValue);

      return(value);
   }
};
const int SMA::MAIN = 0;

#endif // __SMA_MQH__
//+------------------------------------------------------------------+
