/**
 * @file SMMA - Concrete Streaming Smoothed Moving Average indicator using synchronized time-series events and smoothed averaging.
 * @deps IndicatorBase.mqh, BarSeriesBuffer.mqh, SmoothedAverage.mqh
 * @state Stateful (Orchestrates time-series buffers and recursive smoothed average calculations across ticks)
 * @io   Source struct pricing tick -> Updates smoothed average and underlying time buffers | Request offset index -> Returns historical SMMA double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __SMMA_MQH__
#define __SMMA_MQH__

#include "IndicatorBase.mqh"
#include "..\\Algorithms\\SmoothedAverage.mqh"
#include "..\\Storage\\BarSeriesBuffer.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class SMMA : public IndicatorBase
{
private:

   int                m_period;
   double             m_alpha;
   CBarSeriesBuffer   m_input;
   CBarSeriesBuffer   m_main;

public:

   static const int MAIN;

   SMMA()
   {
      m_period = 0;
      m_alpha  = 0.0;
   }

   ~SMMA()
   {
   }

   void SetParameters(const int period)
   {
      m_period = period;
   }

   virtual bool Init()
   {
      if(m_period <= 0)
         return(false);

      if(m_maxBarsBack == 0)
         m_maxBarsBack = m_period;

      if(m_maxBarsBack <= 0)
         return(false);

      m_alpha = 1.0 / m_period;

      if(!m_input.Init(m_period))
         return(false);

      if(!m_main.Init(m_maxBarsBack))
         return(false);

      return(true);
   }

   virtual void Reset()
   {
      m_input.Reset();
      m_main.Reset();
   }

   virtual void DeInit()
   {
      Reset();
   }

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
            result = SmoothedAverage(src.value, previous, m_alpha);

         break;
      }

      case SERIES_REPLACE_LAST:
      {
         double previous;

         if(m_main.At(1, previous))
            result = SmoothedAverage(src.value, previous, m_alpha);

         break;
      }

      case SERIES_RESET:
         m_main.Reset();
         break;
      }

      m_main.Update(src.time, result);
   }

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

const int SMMA::MAIN = 0;

#endif // __SMMA_MQH__
//+------------------------------------------------------------------+
