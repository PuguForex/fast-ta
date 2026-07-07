/**
 * @file EMA - Concrete Streaming Exponential Moving Average indicator using synchronized time-series events and exponential averaging.
 * @deps IndicatorBase.mqh, BarSeriesBuffer.mqh, ExponentialAverage.mqh
 * @state Stateful (Orchestrates time-series buffers and recursive exponential average calculations across ticks)
 * @io   Source struct pricing tick -> Updates exponential average and underlying time buffers | Request offset index -> Returns historical EMA double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __EMA_MQH__
#define __EMA_MQH__

#include "IndicatorBase.mqh"
#include "..\\Algorithms\\ExponentialAverage.mqh"
#include "..\\Storage\\BarSeriesBuffer.mqh"

//+------------------------------------------------------------------+
//| EMA                                                              |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Streaming Exponential Moving Average indicator.                  |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Maintain EMA configuration                                     |
//| • Orchestrate input series, events, and exponential average      |
//| • Calculate EMA values                                           |
//| • Persist calculated output                                      |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Circular storage implementation                                |
//| • Exponential average implementation                             |
//| • MT5 lifecycle management                                       |
//+------------------------------------------------------------------+
class EMA : public IndicatorBase
{
private:

   int                m_period;
   double             m_alpha;
   CBarSeriesBuffer   m_input;
   CBarSeriesBuffer   m_main;

public:

   static const int MAIN;

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   EMA()
   {
      m_period = 0;
      m_alpha  = 0.0;
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                       |
   //+------------------------------------------------------------------+
   ~EMA()
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

      m_alpha = 2.0 / (1.0 + m_period);

      if(!m_input.Init(m_period))
         return(false);

      if(!m_main.Init(m_maxBarsBack))
         return(false);

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Reset                                                            |
   //+------------------------------------------------------------------+
   virtual void Reset()
   {
      m_input.Reset();
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

      double result = src.value;

      switch(event)
      {
      case SERIES_FIRST_SAMPLE:
         break;

      case SERIES_APPEND:
      {
         double previous;

         if(m_main.At(0, previous))
            result = ExponentialAverage(src.value, previous, m_alpha);

         break;
      }

      case SERIES_REPLACE_LAST:
      {
         double previous;

         if(m_main.At(1, previous))
            result = ExponentialAverage(src.value, previous, m_alpha);

         break;
      }

      case SERIES_RESET:
         m_main.Reset();
         break;
      }

      m_main.Update(src.time, result);
   }

   //+------------------------------------------------------------------+
   //| Value Access                                                     |
   //+------------------------------------------------------------------+
   virtual double GetValue(const int index,
                           const int lineIndex = 0) const
   {
      if(lineIndex != MAIN)
         return(m_errorValue);

      double value;

      if(!m_main.At(index, value))
         return(m_errorValue);

      return(value);
   }
};

const int EMA::MAIN = 0;

#endif // __EMA_MQH__
//+------------------------------------------------------------------+
