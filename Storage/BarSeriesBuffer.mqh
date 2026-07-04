/**
 * @file BarSeriesBuffer - Adapts a circular buffer to MT5's tick-driven model, tracking bar times to ensure exactly one sample per bar.
 * @deps CircularBuffer.mqh, ESeriesEvent.mqh
 * @state Stateful (Tracks last processed bar datetime, initialization flags, and internal buffer state across ticks)
 * @io   Current bar datetime & double value -> Returns ESeriesEvent state transition enum & Updates or appends to buffer
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __BARSERIESBUFFER_MQH__
#define __BARSERIESBUFFER_MQH__

#include "..\\Storage\\CircularBuffer.mqh"
#include "..\\Common\\ESeriesEvent.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBarSeriesBuffer
{
private:

   CCircularBuffer   m_buffer;
   datetime          m_lastBarTime;
   bool              m_initialized;
   double            m_droppedValue;

public:

   CBarSeriesBuffer()
   {
      m_lastBarTime = 0;
      m_initialized = false;
      m_droppedValue = 0.0;
   }

   bool Init(const int capacity)
   {
      if(!m_buffer.Init(capacity))
         return(false);

      m_lastBarTime = 0;
      m_initialized = false;
      m_droppedValue = 0.0;

      return(true);
   }

   void Reset()
   {
      m_buffer.Reset();

      m_lastBarTime = 0;
      m_initialized = false;
      m_droppedValue = 0.0;
   }

   ESeriesEvent Update(const datetime barTime, const double value)
   {
      //m_droppedValue = 0.0;

      // First sample
      if(!m_initialized)
      {
         m_buffer.Push(value);

         m_lastBarTime = barTime;
         m_initialized = true;

         return ESeriesEvent::SERIES_FIRST_SAMPLE;
      }

      // History reload / rewind
      if(barTime < m_lastBarTime)
      {
         Reset();

         m_buffer.Push(value);

         m_lastBarTime = barTime;
         m_initialized = true;

         return ESeriesEvent::SERIES_RESET;
      }

      // New bar
      if(barTime != m_lastBarTime)
      {
         if(m_buffer.IsFull())
            m_buffer.At(m_buffer.Capacity() - 1, m_droppedValue);

         m_buffer.Push(value);
         m_lastBarTime = barTime;

         return ESeriesEvent::SERIES_APPEND;
      }

      // Same bar
      m_buffer.UpdateLast(value);
      return ESeriesEvent::SERIES_REPLACE_LAST;
   }

   bool At(const int offset,
           double &value) const
   {
      return(m_buffer.At(offset, value));
   }

   int Count() const
   {
      return(m_buffer.Count());
   }

   int Capacity() const
   {
      return(m_buffer.Capacity());
   }

   bool IsFull() const
   {
      return(m_buffer.IsFull());
   }

   double DroppedValue() const
   {
      return(m_droppedValue);
   }
};

#endif // __BARSERIESBUFFER_MQH__
//+------------------------------------------------------------------+
