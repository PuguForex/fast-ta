/**
 * @file LinearWeightedAverage - Stateful O(1) linear weighted average arithmetic accumulator.
 * @deps None
 * @state Stateful (Maintains current and committed weighted sums across bar and tick updates)
 * @io   Current value + previous ordinary sum + weight -> Updates weighted sum | Request value -> Returns current weighted sum
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __LINEAR_WEIGHTED_AVERAGE_MQH__
#define __LINEAR_WEIGHTED_AVERAGE_MQH__

//+------------------------------------------------------------------+
//| CLinearWeightedAverage                                           |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Maintains a linear weighted sum using O(1) scalar operations.     |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Maintain current weighted sum                                  |
//| • Maintain committed weighted sum                                |
//| • Support rollback and rollover                                  |
//| • Update weighted sum in constant time                           |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Series storage                                                 |
//| • Ordinary rolling sum calculation                               |
//| • Period management                                              |
//| • Stream event handling                                          |
//+------------------------------------------------------------------+
class CLinearWeightedAverage
{
private:

   double m_currentWeightedSum;
   double m_lastWeightedSum;

public:

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   CLinearWeightedAverage()
   {
      m_currentWeightedSum = 0.0;
      m_lastWeightedSum    = 0.0;
   }

   //+------------------------------------------------------------------+
   //| Reset                                                            |
   //+------------------------------------------------------------------+
   void Reset()
   {
      m_currentWeightedSum = 0.0;
      m_lastWeightedSum    = 0.0;
   }

   //+------------------------------------------------------------------+
   //| Roll Back                                                        |
   //+------------------------------------------------------------------+
   void RollBack()
   {
      m_currentWeightedSum = m_lastWeightedSum;
   }

   //+------------------------------------------------------------------+
   //| Update                                                           |
   //+------------------------------------------------------------------+
   void Update(const double value,
               const double previousSum,
               const int weight)
   {
      m_currentWeightedSum += (weight * value) - previousSum;
   }

   //+------------------------------------------------------------------+
   //| Roll Over                                                        |
   //+------------------------------------------------------------------+
   void RollOver()
   {
      m_lastWeightedSum = m_currentWeightedSum;
   }

   //+------------------------------------------------------------------+
   //| Value                                                            |
   //+------------------------------------------------------------------+
   double Value() const
   {
      return(m_currentWeightedSum);
   }
};

#endif // __LINEAR_WEIGHTED_AVERAGE_MQH__
//+------------------------------------------------------------------+
