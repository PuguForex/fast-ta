/**
 * @file CircularBuffer - Manages a fixed-size, FIFO data buffer for real-time financial indicators.
 * @deps MQL5 Standard Library (ArrayResize function)
 * @state Stateful (Maintains internal ring index, capacity, and historical price/indicator count in memory)
 * @io   New double value -> Stores at head index & overwrites oldest data | Offset index -> Retrieves past historical double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __CIRCULAR_BUFFER_MQH__
#define __CIRCULAR_BUFFER_MQH__

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CCircularBuffer
{
private:
   double m_data[];
   int    m_capacity;
   int    m_count;
   int    m_head;

public:
   CCircularBuffer()
   {
      m_capacity = 0;
      m_count = 0;
      m_head = 0;
   }

   bool Init(const int capacity)
   {
      if(capacity <= 0)
         return(false);

      if(ArrayResize(m_data, capacity) != capacity)
         return(false);

      m_capacity = capacity;
      m_count = 0;
      m_head = 0;

      return(true);
   }

   void Reset()
   {
      m_count = 0;
      m_head = 0;
   }

   void Push(const double value)
   {
      if(m_capacity == 0)
         return;

      m_data[m_head] = value;
      m_head = (m_head + 1) % m_capacity;

      if(m_count < m_capacity)
         ++m_count;
   }

   bool UpdateLast(const double value)
   {
      if(m_count == 0)
         return(false);

      int index = m_head - 1;
      if(index < 0)
         index += m_capacity;

      m_data[index] = value;
      return(true);
   }

   bool At(const int offset, double &value) const
   {
      if(offset < 0 || offset >= m_count)
         return(false);

      int index = (m_head - 1 - offset + m_capacity) % m_capacity;

      value = m_data[index];
      return(true);
   }

   int Count() const
   {
      return(m_count);
   }

   int Capacity() const
   {
      return(m_capacity);
   }

   bool IsFull() const
   {
      return(m_count == m_capacity);
   }
};

#endif // __CIRCULAR_BUFFER_MQH__
