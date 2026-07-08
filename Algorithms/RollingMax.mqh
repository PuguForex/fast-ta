/**
 * @file RollingMax - Stateful O(1) amortized rolling maximum algorithm using delayed live-value insertion and monotonic deque storage.
 * @deps MonotonicDeque.mqh
 * @state Stateful (Maintains committed historical maximum candidates and a separately tracked live value)
 * @io   Appended or replaced double values -> Updates rolling maximum state | Request value -> Returns current rolling maximum
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __ROLLING_MAX_MQH__
#define __ROLLING_MAX_MQH__

#include "..\\Storage\\MonotonicDeque.mqh"

//+------------------------------------------------------------------+
//| CRollingMax                                                      |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Maintains a rolling maximum using O(1) amortized operations.      |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Maintain committed historical maximum candidates              |
//| • Maintain current live value separately                         |
//| • Commit finalized live values on append                         |
//| • Evict expired historical candidates                            |
//| • Support arbitrary live-value replacement                       |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Deque storage implementation                                   |
//| • Series storage                                                 |
//| • Stream event handling                                          |
//+------------------------------------------------------------------+
class CRollingMax
{
private:

   CMonotonicDeque m_deque;
   int             m_capacity;
   long            m_nextIndex;
   double          m_liveValue;
   bool            m_hasLive;

   //+------------------------------------------------------------------+
   //| Commit                                                           |
   //+------------------------------------------------------------------+
   void Commit(const double value)
   {
      if(m_capacity == 1)
         return;

      long index = m_nextIndex++;

      long frontIndex;
      double frontValue;

      long expiry = index - (m_capacity - 1);

      while(m_deque.Front(frontIndex, frontValue) &&
            frontIndex <= expiry)
      {
         m_deque.PopFront();
      }

      long backIndex;
      double backValue;

      while(m_deque.Back(backIndex, backValue) &&
            backValue <= value)
      {
         m_deque.PopBack();
      }

      m_deque.PushBack(index, value);
   }

public:

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   CRollingMax()
   {
      m_capacity  = 0;
      m_nextIndex = 0;
      m_liveValue = 0.0;
      m_hasLive   = false;
   }

   //+------------------------------------------------------------------+
   //| Initialize                                                       |
   //+------------------------------------------------------------------+
   bool Init(const int capacity)
   {
      if(capacity <= 0)
         return(false);

      if(!m_deque.Init(capacity))
         return(false);

      m_capacity = capacity;

      Reset();

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Reset                                                            |
   //+------------------------------------------------------------------+
   void Reset()
   {
      m_deque.Reset();

      m_nextIndex = 0;
      m_liveValue = 0.0;
      m_hasLive   = false;
   }

   //+------------------------------------------------------------------+
   //| Append                                                           |
   //+------------------------------------------------------------------+
   void Append(const double value)
   {
      if(m_hasLive)
         Commit(m_liveValue);

      m_liveValue = value;
      m_hasLive   = true;
   }

   //+------------------------------------------------------------------+
   //| Replace Last                                                     |
   //+------------------------------------------------------------------+
   bool ReplaceLast(const double value)
   {
      if(!m_hasLive)
         return(false);

      m_liveValue = value;

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Value                                                            |
   //+------------------------------------------------------------------+
   double Value() const
   {
      if(!m_hasLive)
         return(0.0);

      long frontIndex;
      double frontValue;

      if(!m_deque.Front(frontIndex, frontValue))
         return(m_liveValue);

      return(MathMax(frontValue, m_liveValue));
   }
};

#endif // __ROLLING_MAX_MQH__
//+------------------------------------------------------------------+
