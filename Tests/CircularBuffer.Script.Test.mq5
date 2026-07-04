//+------------------------------------------------------------------+
//|                                   CircularBuffer.Script.Test.mq5 |
//+------------------------------------------------------------------+
#property script_show_inputs

// Update this path to match your CircularBuffer file location
#include "..\\Storage\\CircularBuffer.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("--- Starting CircularBuffer Minimal Test ---");

   CCircularBuffer buffer;

// 1. Test Initialization
   if(!buffer.Init(3))
   {
      Print("FAIL: Initialization failed.");
      return;
   }

// 2. Push elements to fill capacity (Size: 3)
   buffer.Push(10.0); // Oldest (Offset 2)
   buffer.Push(20.0); // Middle (Offset 1)
   buffer.Push(30.0); // Newest (Offset 0)

// Verify states
   if(buffer.Count() != 3 || !buffer.IsFull())
   {
      PrintFormat("FAIL: Count expected 3, got %d. IsFull expected true.", buffer.Count());
      return;
   }

// 3. Test data retrieval matching standard MQL5 serial index (0 = latest)
   double val0 = 0, val1 = 0, val2 = 0;
   buffer.At(0, val0);
   buffer.At(1, val1);
   buffer.At(2, val2);

   if(val0 != 30.0 || val1 != 20.0 || val2 != 10.0)
   {
      PrintFormat("FAIL: Indexing error. Got=%.1f,=%.1f,=%.1f", val0, val1, val2);
      return;
   }

// 4. Test Overwriting (Pushing 40.0 should drop 10.0)
   buffer.Push(40.0);

   double oldestVal = 0;
   buffer.At(2, oldestVal); // This offset should now pull 20.0 instead of 10.0

   if(oldestVal != 20.0)
   {
      PrintFormat("FAIL: FIFO wrapping failed. Expected offset 2 to be 20.0, got %.1f", oldestVal);
      return;
   }

// 5. Test UpdateLast (Modifying the current live bar/tick value)
   if(!buffer.UpdateLast(45.5))
   {
      Print("FAIL: UpdateLast execution failed.");
      return;
   }

   double latestVal = 0;
   buffer.At(0, latestVal);
   if(latestVal != 45.5)
   {
      PrintFormat("FAIL: UpdateLast did not modify head. Expected 45.5, got %.1f", latestVal);
      return;
   }

   Print("SUCCESS: All core components passed unit testing!");
}
//+------------------------------------------------------------------+
