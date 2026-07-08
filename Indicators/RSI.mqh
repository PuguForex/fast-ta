/**
 * @file RSI - Concrete Streaming Relative Strength Index indicator using synchronized time-series events and Smoothed Moving Average indicators.
 * @deps IndicatorBase.mqh, BarSeriesBuffer.mqh, SMMA.mqh
 * @state Stateful (Orchestrates input price history, internal gain and loss averages, and output time-series buffers across ticks)
 * @io   Source struct pricing tick -> Updates gain and loss averages and underlying time buffers | Request offset index -> Returns historical RSI double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __RSI_MQH__
#define __RSI_MQH__

#include "IndicatorBase.mqh"
#include "SMMA.mqh"
#include "..\\Storage\\BarSeriesBuffer.mqh"

//+------------------------------------------------------------------+
//| RSI                                                              |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Streaming Relative Strength Index indicator.                     |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Maintain RSI configuration                                     |
//| • Calculate price changes                                        |
//| • Orchestrate gain and loss moving averages                      |
//| • Calculate RSI values                                           |
//| • Persist calculated output                                      |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Circular storage implementation                                |
//| • Smoothed moving average implementation                         |
//| • MT5 lifecycle management                                       |
//+------------------------------------------------------------------+
class RSI : public IndicatorBase
{
private:

   int                m_period;
   CBarSeriesBuffer   m_input;
   SMMA               m_up;
   SMMA               m_down;
   CBarSeriesBuffer   m_main;

public:

   static const int MAIN;

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   RSI()
   {
      m_period = 0;
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                       |
   //+------------------------------------------------------------------+
   ~RSI()
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

      m_up.SetParameters(m_period);
      m_up.SetMaxBarsBack(m_maxBarsBack);
      m_up.SetErrorValue(m_errorValue);

      if(!m_up.Init())
         return(false);

      m_down.SetParameters(m_period);
      m_down.SetMaxBarsBack(m_maxBarsBack);
      m_down.SetErrorValue(m_errorValue);

      if(!m_down.Init())
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
      m_up.Reset();
      m_down.Reset();
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

      double change = 0.0;

      if(event == SERIES_APPEND ||
            event == SERIES_REPLACE_LAST)
      {
         double previous;

         if(m_input.At(1, previous))
            change = src.value - previous;
      }

      Source upSource;
      upSource.time  = src.time;
      upSource.value = MathMax(change, 0.0);

      Source downSource;
      downSource.time  = src.time;
      downSource.value = -MathMin(change, 0.0);

      if(event == SERIES_RESET)
      {
         m_up.Reset();
         m_down.Reset();
         m_main.Reset();
      }

      m_up.Update(upSource);
      m_down.Update(downSource);

      double result = m_errorValue;

      double up   = m_up.GetValue(0, SMMA::MAIN);
      double down = m_down.GetValue(0, SMMA::MAIN);

      if(m_input.IsFull())
      {
         if(down == 0.0)
            result = 100.0;
         else if(up == 0.0)
            result = 0.0;
         else
            result = 100.0 - (100.0 / (1.0 + (up / down)));
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

const int RSI::MAIN = 0;

#endif // __RSI_MQH__
//+------------------------------------------------------------------+
