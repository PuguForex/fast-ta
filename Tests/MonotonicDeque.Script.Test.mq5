//+------------------------------------------------------------------+
//|                                    MonotonicDeque.Script.Test.mq5 |
//+------------------------------------------------------------------+
#property script_show_inputs

#include "..\\Storage\\MonotonicDeque.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("--- Starting MonotonicDeque Minimal Test ---");

   CMonotonicDeque deque;

// 1. Test Initialization
   if(!deque.Init(3))
   {
      Print("FAIL: Initialization failed.");
      return;
   }

   if(deque.Capacity() != 3 || deque.Count() != 0 || !deque.IsEmpty())
   {
      Print("FAIL: Invalid initial state.");
      return;
   }

// 2. Test PushBack
   if(!deque.PushBack(10, 100.0) ||
         !deque.PushBack(20, 200.0) ||
         !deque.PushBack(30, 300.0))
   {
      Print("FAIL: PushBack execution failed.");
      return;
   }

   if(deque.Count() != 3 || !deque.IsFull())
   {
      PrintFormat("FAIL: Count expected 3, got %d. IsFull expected true.", deque.Count());
      return;
   }

// 3. Test Front and Back access
   long frontIndex = 0;
   long backIndex  = 0;

   double frontValue = 0.0;
   double backValue  = 0.0;

   if(!deque.Front(frontIndex, frontValue) ||
         !deque.Back(backIndex, backValue))
   {
      Print("FAIL: Front or Back access failed.");
      return;
   }

   if(frontIndex != 10 || frontValue != 100.0 ||
         backIndex != 30 || backValue != 300.0)
   {
      PrintFormat("FAIL: Boundary access error. Front=(%I64d, %.1f), Back=(%I64d, %.1f)",
                  frontIndex, frontValue, backIndex, backValue);
      return;
   }

// 4. Test full-capacity rejection
   if(deque.PushBack(40, 400.0))
   {
      Print("FAIL: PushBack succeeded on full deque.");
      return;
   }

// 5. Test PopFront
   if(!deque.PopFront())
   {
      Print("FAIL: PopFront execution failed.");
      return;
   }

   if(!deque.Front(frontIndex, frontValue))
   {
      Print("FAIL: Front access after PopFront failed.");
      return;
   }

   if(frontIndex != 20 || frontValue != 200.0)
   {
      PrintFormat("FAIL: PopFront error. Expected (20, 200.0), got (%I64d, %.1f)",
                  frontIndex, frontValue);
      return;
   }

// 6. Test circular wrapping
   if(!deque.PushBack(40, 400.0))
   {
      Print("FAIL: PushBack after PopFront failed.");
      return;
   }

   if(!deque.Back(backIndex, backValue))
   {
      Print("FAIL: Back access after circular wrapping failed.");
      return;
   }

   if(backIndex != 40 || backValue != 400.0)
   {
      PrintFormat("FAIL: Circular wrapping error. Expected (40, 400.0), got (%I64d, %.1f)",
                  backIndex, backValue);
      return;
   }

// 7. Test PopBack
   if(!deque.PopBack())
   {
      Print("FAIL: PopBack execution failed.");
      return;
   }

   if(!deque.Back(backIndex, backValue))
   {
      Print("FAIL: Back access after PopBack failed.");
      return;
   }

   if(backIndex != 30 || backValue != 300.0)
   {
      PrintFormat("FAIL: PopBack error. Expected (30, 300.0), got (%I64d, %.1f)",
                  backIndex, backValue);
      return;
   }

// 8. Test Reset
   deque.Reset();

   if(deque.Count() != 0 || !deque.IsEmpty() || deque.IsFull())
   {
      Print("FAIL: Reset did not restore empty state.");
      return;
   }

// 9. Test empty-operation rejection
   if(deque.PopFront() ||
         deque.PopBack() ||
         deque.Front(frontIndex, frontValue) ||
         deque.Back(backIndex, backValue))
   {
      Print("FAIL: Empty deque operation unexpectedly succeeded.");
      return;
   }

   Print("SUCCESS: All MonotonicDeque core components passed unit testing!");
}
//+------------------------------------------------------------------+
