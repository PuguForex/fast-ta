/**
 * @file Stochastic - Concrete Streaming Stochastic indicator using rolling extrema, Simple Moving Average slowing, and configurable signal-line smoothing.
 * @deps IndicatorBase.mqh, SMA.mqh, EMA.mqh, SMMA.mqh, LWMA.mqh, BarSeriesBuffer.mqh, RollingMin.mqh, RollingMax.mqh, EMovingAverageType.mqh
 * @state Stateful (Orchestrates rolling extrema, internal moving averages, dynamic signal-line ownership, and output time-series buffers across ticks)
 * @io   Source struct OHLC pricing tick -> Updates rolling extrema, smoothed K, signal D, and output buffers | Request offset and line index -> Returns historical K or D double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __STOCHASTIC_MQH__
#define __STOCHASTIC_MQH__

#include "IndicatorBase.mqh"
#include "SMA.mqh"
#include "EMA.mqh"
#include "SMMA.mqh"
#include "LWMA.mqh"
#include "..\\Storage\\BarSeriesBuffer.mqh"
#include "..\\Algorithms\\RollingMin.mqh"
#include "..\\Algorithms\\RollingMax.mqh"
#include "..\\Common\\EMovingAverageType.mqh"

//+------------------------------------------------------------------+
//| Stochastic                                                       |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Streaming Stochastic indicator.                                  |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Maintain Stochastic configuration                              |
//| • Maintain rolling highest and lowest values                     |
//| • Calculate and smooth raw K values                              |
//| • Calculate configurable signal D values                         |
//| • Persist calculated K and D outputs                             |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Rolling extrema implementation                                 |
//| • Moving average implementation                                  |
//| • Circular storage implementation                                |
//| • MT5 lifecycle management                                       |
//+------------------------------------------------------------------+
class Stochastic : public IndicatorBase
{
private:

   int                   m_kPeriod;
   int                   m_dPeriod;
   int                   m_slowingPeriod;
   EMovingAverageType    m_maType;

   CBarSeriesBuffer      m_input;
   CRollingMin           m_rollingMin;
   CRollingMax           m_rollingMax;

   SMA                   m_numeratorSMA;
   SMA                   m_denominatorSMA;
   IndicatorBase        *m_signal;

   CBarSeriesBuffer      m_main;
   CBarSeriesBuffer      m_signalLine;

public:

   static const int MAIN;
   static const int SIGNAL;

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   Stochastic()
   {
      m_kPeriod       = 0;
      m_dPeriod       = 0;
      m_slowingPeriod = 0;
      m_maType         = MA_SIMPLE;
      m_signal         = NULL;
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                       |
   //+------------------------------------------------------------------+
   ~Stochastic()
   {
      DeInit();
   }

   //+------------------------------------------------------------------+
   //| Parameters                                                       |
   //+------------------------------------------------------------------+
   void SetParameters(const int kPeriod,
                      const int dPeriod,
                      const int slowingPeriod,
                      const EMovingAverageType maType)
   {
      m_kPeriod       = kPeriod;
      m_dPeriod       = dPeriod;
      m_slowingPeriod = slowingPeriod;
      m_maType         = maType;
   }

   //+------------------------------------------------------------------+
   //| Initialize                                                       |
   //+------------------------------------------------------------------+
   virtual bool Init()
   {
      DeInit();

      if(m_kPeriod <= 0 ||
            m_dPeriod <= 0 ||
            m_slowingPeriod <= 0)
      {
         return(false);
      }

      if(m_maxBarsBack == 0)
         m_maxBarsBack = m_kPeriod;

      if(m_maxBarsBack <= 0)
         return(false);

      if(!m_input.Init(m_kPeriod))
         return(false);

      if(!m_rollingMin.Init(m_kPeriod))
         return(false);

      if(!m_rollingMax.Init(m_kPeriod))
         return(false);

      m_numeratorSMA.SetParameters(m_slowingPeriod);
      m_numeratorSMA.SetMaxBarsBack(m_maxBarsBack);
      m_numeratorSMA.SetErrorValue(m_errorValue);

      if(!m_numeratorSMA.Init())
         return(false);

      m_denominatorSMA.SetParameters(m_slowingPeriod);
      m_denominatorSMA.SetMaxBarsBack(m_maxBarsBack);
      m_denominatorSMA.SetErrorValue(m_errorValue);

      if(!m_denominatorSMA.Init())
         return(false);

      switch(m_maType)
      {
      case MA_SIMPLE:
         m_signal = new SMA;
         break;

      case MA_EXPONENTIAL:
         m_signal = new EMA;
         break;

      case MA_SMOOTHED:
         m_signal = new SMMA;
         break;

      case MA_LINEAR_WEIGHTED:
         m_signal = new LWMA;
         break;

      default:
         return(false);
      }

      if(CheckPointer(m_signal) != POINTER_DYNAMIC)
      {
         m_signal = NULL;
         return(false);
      }

      if(m_maType == MA_SIMPLE)
         ((SMA*)m_signal).SetParameters(m_dPeriod);
      else if(m_maType == MA_EXPONENTIAL)
         ((EMA*)m_signal).SetParameters(m_dPeriod);
      else if(m_maType == MA_SMOOTHED)
         ((SMMA*)m_signal).SetParameters(m_dPeriod);
      else
         ((LWMA*)m_signal).SetParameters(m_dPeriod);

      m_signal.SetMaxBarsBack(m_maxBarsBack);
      m_signal.SetErrorValue(m_errorValue);

      if(!m_signal.Init())
      {
         DeInit();
         return(false);
      }

      if(!m_main.Init(m_maxBarsBack))
      {
         DeInit();
         return(false);
      }

      if(!m_signalLine.Init(m_maxBarsBack))
      {
         DeInit();
         return(false);
      }

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Reset                                                            |
   //+------------------------------------------------------------------+
   virtual void Reset()
   {
      m_input.Reset();
      m_rollingMin.Reset();
      m_rollingMax.Reset();
      m_numeratorSMA.Reset();
      m_denominatorSMA.Reset();

      if(CheckPointer(m_signal) != POINTER_INVALID)
         m_signal.Reset();

      m_main.Reset();
      m_signalLine.Reset();
   }

   //+------------------------------------------------------------------+
   //| Deinitialize                                                     |
   //+------------------------------------------------------------------+
   virtual void DeInit()
   {
      if(CheckPointer(m_signal) == POINTER_DYNAMIC)
         delete m_signal;

      m_signal = NULL;
   }

   //+------------------------------------------------------------------+
   //| Update                                                           |
   //+------------------------------------------------------------------+
   virtual void Update(const Source &src)
   {
      ESeriesEvent event = m_input.Update(src.time, src.close);

      switch(event)
      {
      case SERIES_FIRST_SAMPLE:
         m_rollingMin.Append(src.low);
         m_rollingMax.Append(src.high);
         break;

      case SERIES_APPEND:
         m_rollingMin.Append(src.low);
         m_rollingMax.Append(src.high);
         break;

      case SERIES_REPLACE_LAST:
         m_rollingMin.ReplaceLast(src.low);
         m_rollingMax.ReplaceLast(src.high);
         break;

      case SERIES_RESET:
         Reset();

         m_input.Update(src.time, src.close);
         m_rollingMin.Append(src.low);
         m_rollingMax.Append(src.high);
         break;
      }

      double lowest  = m_rollingMin.Value();
      double highest = m_rollingMax.Value();

      double numerator   = src.close - lowest;
      double denominator = highest - lowest;

      Source numeratorSource =
         Source::From(numerator, src.time);

      Source denominatorSource =
         Source::From(denominator, src.time);

      m_numeratorSMA.Update(numeratorSource);
      m_denominatorSMA.Update(denominatorSource);

      double numeratorAverage =
         m_numeratorSMA.GetValue(0, SMA::MAIN);

      double denominatorAverage =
         m_denominatorSMA.GetValue(0, SMA::MAIN);

      double smoothedK = m_errorValue;

      if(numeratorAverage != m_errorValue &&
            denominatorAverage != m_errorValue)
      {
         smoothedK = denominatorAverage == 0.0
                     ? 0.0
                     : 100.0 * numeratorAverage / denominatorAverage;
      }

      double signalD = m_errorValue;

      if(smoothedK != m_errorValue)
      {
         Source signalSource = Source::From(smoothedK, src.time);

         m_signal.Update(signalSource);
         signalD = m_signal.GetValue(0, 0);
      }

      m_main.Update(src.time, smoothedK);
      m_signalLine.Update(src.time, signalD);
   }

   //+------------------------------------------------------------------+
   //| Value Access                                                     |
   //+------------------------------------------------------------------+
   virtual double GetValue(const int index,
                           const int lineIndex = 0) const
   {
      double value;

      if(lineIndex == MAIN)
      {
         if(m_main.At(index, value))
            return(value);
      }
      else if(lineIndex == SIGNAL)
      {
         if(m_signalLine.At(index, value))
            return(value);
      }

      return(m_errorValue);
   }
};

const int Stochastic::MAIN   = 0;
const int Stochastic::SIGNAL = 1;

#endif // __STOCHASTIC_MQH__
//+------------------------------------------------------------------+
