/**
 * @file MonotonicDeque - Fixed-capacity double-ended queue storage for monotonic rolling algorithms.
 * @deps None
 * @state Stateful (Maintains fixed-capacity indexed value storage with front and back access)
 * @io   Indexed double values -> Supports deque insertion, removal, and boundary access
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __MONOTONIC_DEQUE_MQH__
#define __MONOTONIC_DEQUE_MQH__

//+------------------------------------------------------------------+
//| CMonotonicDeque                                                  |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Provides fixed-capacity deque storage for rolling algorithms.    |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Store indexed double values                                    |
//| • Push values at the back                                        |
//| • Remove values from front or back                               |
//| • Provide front and back access                                  |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • Monotonic ordering                                             |
//| • Rolling minimum or maximum calculation                         |
//| • Stream event handling                                          |
//+------------------------------------------------------------------+
class CMonotonicDeque
{
private:

   double m_values[];
   long   m_indices[];
   int    m_capacity;
   int    m_count;
   int    m_head;

public:

   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   CMonotonicDeque()
   {
      m_capacity = 0;
      m_count    = 0;
      m_head     = 0;
   }

   //+------------------------------------------------------------------+
   //| Initialize                                                       |
   //+------------------------------------------------------------------+
   bool Init(const int capacity)
   {
      if(capacity <= 0)
         return(false);

      if(ArrayResize(m_values, capacity) != capacity)
         return(false);

      if(ArrayResize(m_indices, capacity) != capacity)
         return(false);

      m_capacity = capacity;
      m_count    = 0;
      m_head     = 0;

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Reset                                                            |
   //+------------------------------------------------------------------+
   void Reset()
   {
      m_count = 0;
      m_head  = 0;
   }

   //+------------------------------------------------------------------+
   //| Push Back                                                        |
   //+------------------------------------------------------------------+
   bool PushBack(const long index,
                 const double value)
   {
      if(m_capacity == 0 || m_count == m_capacity)
         return(false);

      int position = (m_head + m_count) % m_capacity;

      m_indices[position] = index;
      m_values[position]  = value;

      ++m_count;

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Pop Front                                                        |
   //+------------------------------------------------------------------+
   bool PopFront()
   {
      if(m_count == 0)
         return(false);

      m_head = (m_head + 1) % m_capacity;
      --m_count;

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Pop Back                                                         |
   //+------------------------------------------------------------------+
   bool PopBack()
   {
      if(m_count == 0)
         return(false);

      --m_count;

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Front                                                            |
   //+------------------------------------------------------------------+
   bool Front(long &index,
              double &value) const
   {
      if(m_count == 0)
         return(false);

      index = m_indices[m_head];
      value = m_values[m_head];

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Back                                                             |
   //+------------------------------------------------------------------+
   bool Back(long &index,
             double &value) const
   {
      if(m_count == 0)
         return(false);

      int position = (m_head + m_count - 1) % m_capacity;

      index = m_indices[position];
      value = m_values[position];

      return(true);
   }

   //+------------------------------------------------------------------+
   //| Information                                                      |
   //+------------------------------------------------------------------+
   int Count() const
   {
      return(m_count);
   }

   int Capacity() const
   {
      return(m_capacity);
   }

   bool IsEmpty() const
   {
      return(m_count == 0);
   }

   bool IsFull() const
   {
      return(m_count == m_capacity);
   }
};

#endif // __MONOTONIC_DEQUE_MQH__
//+------------------------------------------------------------------+
