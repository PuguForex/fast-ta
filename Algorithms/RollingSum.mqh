/**
 * @file RollingSum - Maintains a high-performance moving window accumulation via subtraction of outgoing values and addition of incoming values.
 * @deps None (Independent math utility module)
 * @state Stateful (Tracks active sum and historical state to support roll-back operations during real-time tick ticks)
 * @io   Incoming value & Outgoing value -> Mutates and accumulates aggregate double sum | Read -> Outputs active sum
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __ROLLING_SUM_MQH__
#define __ROLLING_SUM_MQH__

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRollingSum
{
private:
   double m_currentSum;
   double m_lastSum;

public:
   CRollingSum()
   {
      m_currentSum = 0.0;
      m_lastSum    = 0.0;
   }

   void Reset()
   {
      m_currentSum = 0.0;
      m_lastSum    = 0.0;
   }

   void RollBack()
   {
      m_currentSum = m_lastSum;
   }

   void Update(const double addValue,
               const double subtractValue)
   {
      m_currentSum += addValue - subtractValue;
   }

   void RollOver()
   {
      m_lastSum = m_currentSum;
   }

   double Value() const
   {
      return(m_currentSum);
   }
};

#endif // __ROLLING_SUM_MQH__
//+------------------------------------------------------------------+
