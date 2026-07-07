/**
 * @file LWMA - Concrete Streaming Linear Weighted Moving Average indicator using synchronized time-series events and constant-time rolling arithmetic.
 * @deps IndicatorBase.mqh, BarSeriesBuffer.mqh, RollingSum.mqh, LinearWeightedAverage.mqh
 * @state Stateful (Orchestrates time-series buffers, rolling sums, and linear weighted arithmetic accumulators across ticks)
 * @io   Source struct pricing tick -> Updates rolling and weighted sums and underlying time buffers | Request offset index -> Returns historical LWMA double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __LWMA_MQH__
#define __LWMA_MQH__

#include "IndicatorBase.mqh"
#include "..\\Storage\\BarSeriesBuffer.mqh"
#include "..\\Algorithms\\RollingSum.mqh"
#include "..\\Algorithms\\LinearWeightedAverage.mqh"

//+------------------------------------------------------------------+
//| LWMA                                                             |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Streaming Linear Weighted Moving Average indicator.              |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Maintain LWMA configuration                                    |
//| • Orchestrate input series, events, and rolling arithmetic       |
//| • Calculate LWMA values in constant time                         |
//| • Persist calculated output                                      |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Circular storage implementation                                |
//| • Rolling arithmetic implementation                              |
//| • MT5 lifecycle management                                       |
//+------------------------------------------------------------------+
class LWMA : public IndicatorBase
{
private:

   int                      m_period;
   double                   m_totalWeight;
   CBarSeriesBuffer         m_input;
   CRollingSum              m_rollingSum;
   CLinearWeightedAverage   m_weightedAverage;
   CBarSeriesBuffer         m_main;

public:

   static const int MAIN;

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   LWMA()
   {
      m_period      = 0;
      m_totalWeight = 0.0;
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                       |
   //+------------------------------------------------------------------+
   ~LWMA()
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

      m_totalWeight = (m_period * (m_period + 1)) / 2.0;

      if(!m_input.Init(m_period))
         return(false);

      if(!m_main.Init(m_maxBarsBack))
         return(false);

      m_rollingSum.Reset();
      m_weightedAverage.Reset();

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Reset                                                            |
   //+------------------------------------------------------------------+
   virtual void Reset()
   {
      m_input.Reset();
      m_rollingSum.Reset();
      m_weightedAverage.Reset();
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
      bool wasFull = m_input.IsFull();
      double previousSum = m_rollingSum.Value();

      ESeriesEvent event = m_input.Update(src.time, src.value);
      double dropped = m_input.DroppedValue();

      switch(event)
      {
      case SERIES_FIRST_SAMPLE:
         m_rollingSum.RollOver();
         m_rollingSum.Update(src.value, 0.0);

         m_weightedAverage.RollOver();
         m_weightedAverage.Update(src.value, 0.0, 1);
         break;

      case SERIES_APPEND:
         m_rollingSum.RollOver();
         m_rollingSum.Update(src.value, dropped);

         m_weightedAverage.RollOver();

         if(wasFull)
            m_weightedAverage.Update(src.value,
                                     previousSum,
                                     m_period);
         else
            m_weightedAverage.Update(src.value,
                                     0.0,
                                     m_input.Count());

         break;

      case SERIES_REPLACE_LAST:
      {
         m_rollingSum.RollBack();
         double previousBarSum = m_rollingSum.Value();

         m_rollingSum.Update(src.value, dropped);

         m_weightedAverage.RollBack();

         m_weightedAverage.Update(src.value,
                                  wasFull ? previousBarSum : 0.0,
                                  m_input.Count());
         break;
      }

      case SERIES_RESET:
         m_rollingSum.Reset();
         m_rollingSum.RollOver();
         m_rollingSum.Update(src.value, 0.0);

         m_weightedAverage.Reset();
         m_weightedAverage.RollOver();
         m_weightedAverage.Update(src.value, 0.0, 1);
         break;
      }

      double result = m_errorValue;

      if(m_input.IsFull())
         result = m_weightedAverage.Value() / m_totalWeight;

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

const int LWMA::MAIN = 0;

#endif // __LWMA_MQH__
//+------------------------------------------------------------------+
