/**
 * @file IndicatorBase - Abstract interface defining the lifecycle, update contract, and data access for all indicators.
 * @deps Source.mqh
 * @state Stateful (Tracks configuration parameters like maximum depth window and fallback error values)
 * @io   Source struct update reference -> Triggers calculation pipeline | Window offset index -> Returns double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __INDICATOR_BASE_MQH__
#define __INDICATOR_BASE_MQH__

#include "..\\Common\\Source.mqh"
#include <Object.mqh>

//+------------------------------------------------------------------+
//| IndicatorBase                                                    |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Defines the common public contract for all indicators.           |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Store universal indicator configuration                        |
//| • Define indicator lifecycle                                     |
//| • Define streaming update contract                               |
//| • Define historical value access contract                        |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Indicator calculations                                         |
//| • Algorithm execution                                             |
//| • Series storage                                                  |
//| • Parameter validation                                            |
//+------------------------------------------------------------------+
class IndicatorBase : public CObject
{
protected:

   int      m_maxBarsBack;
   double   m_errorValue;

public:

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   IndicatorBase()
   {
      m_maxBarsBack = 0;
      m_errorValue  = EMPTY_VALUE;
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                       |
   //+------------------------------------------------------------------+
   virtual ~IndicatorBase()
   {
   }

   //+------------------------------------------------------------------+
   //| Configuration                                                    |
   //+------------------------------------------------------------------+
   void SetMaxBarsBack(const int maxBarsBack)
   {
      m_maxBarsBack = maxBarsBack;
   }

   void SetErrorValue(const double errorValue)
   {
      m_errorValue = errorValue;
   }

   int GetMaxBarsBack() const
   {
      return m_maxBarsBack;
   }

   double GetErrorValue() const
   {
      return m_errorValue;
   }

   //+------------------------------------------------------------------+
   //| Lifecycle                                                        |
   //+------------------------------------------------------------------+
   virtual bool Init() = 0;

   virtual void Reset() = 0;

   virtual void DeInit() = 0;

   //+------------------------------------------------------------------+
   //| Streaming Update                                                 |
   //+------------------------------------------------------------------+
   virtual void Update(const Source &src) = 0;

   //+------------------------------------------------------------------+
   //| Value Access                                                     |
   //+------------------------------------------------------------------+
   virtual double GetValue(const int index,
                           const int lineIndex = 0) const = 0;
};

#endif // __INDICATOR_BASE_MQH__
//+------------------------------------------------------------------+
