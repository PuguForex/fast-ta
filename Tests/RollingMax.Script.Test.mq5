//+------------------------------------------------------------------+
//|                                        RollingMax.Script.Test.mq5 |
//+------------------------------------------------------------------+
#property script_show_inputs

#include "..\\Algorithms\\RollingMax.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("--- Starting RollingMax Minimal Test ---");

   CRollingMax rollingMax;

// 1. Test invalid initialization
   if(rollingMax.Init(0))
   {
      Print("FAIL: Initialization succeeded with zero capacity.");
      return;
   }

   if(rollingMax.Init(-1))
   {
      Print("FAIL: Initialization succeeded with negative capacity.");
      return;
   }

// 2. Test valid initialization and empty state
   if(!rollingMax.Init(3))
   {
      Print("FAIL: Initialization failed.");
      return;
   }

   if(rollingMax.Value() != 0.0)
   {
      PrintFormat("FAIL: Empty value expected 0.0, got %.1f", rollingMax.Value());
      return;
   }

// 3. Test ReplaceLast rejection without live value
   if(rollingMax.ReplaceLast(10.0))
   {
      Print("FAIL: ReplaceLast succeeded without live value.");
      return;
   }

// 4. Test first live value
   rollingMax.Append(10.0);

   if(rollingMax.Value() != 10.0)
   {
      PrintFormat("FAIL: First live value expected 10.0, got %.1f", rollingMax.Value());
      return;
   }

// 5. Test arbitrary live-value replacement upward
   if(!rollingMax.ReplaceLast(15.0))
   {
      Print("FAIL: ReplaceLast upward execution failed.");
      return;
   }

   if(rollingMax.Value() != 15.0)
   {
      PrintFormat("FAIL: Upward replacement expected 15.0, got %.1f", rollingMax.Value());
      return;
   }

// 6. Test arbitrary live-value replacement downward
   if(!rollingMax.ReplaceLast(5.0))
   {
      Print("FAIL: ReplaceLast downward execution failed.");
      return;
   }

   if(rollingMax.Value() != 5.0)
   {
      PrintFormat("FAIL: Downward replacement expected 5.0, got %.1f", rollingMax.Value());
      return;
   }

// 7. Test committed historical maximum
   rollingMax.Append(20.0);

   if(rollingMax.Value() != 20.0)
   {
      PrintFormat("FAIL: New live maximum expected 20.0, got %.1f", rollingMax.Value());
      return;
   }

   rollingMax.Append(10.0);

   if(rollingMax.Value() != 20.0)
   {
      PrintFormat("FAIL: Historical maximum expected 20.0, got %.1f", rollingMax.Value());
      return;
   }

// 8. Test live replacement below historical maximum
   if(!rollingMax.ReplaceLast(8.0))
   {
      Print("FAIL: ReplaceLast below historical maximum failed.");
      return;
   }

   if(rollingMax.Value() != 20.0)
   {
      PrintFormat("FAIL: Historical maximum after replacement expected 20.0, got %.1f", rollingMax.Value());
      return;
   }

// 9. Test live replacement above historical maximum
   if(!rollingMax.ReplaceLast(25.0))
   {
      Print("FAIL: ReplaceLast above historical maximum failed.");
      return;
   }

   if(rollingMax.Value() != 25.0)
   {
      PrintFormat("FAIL: Replaced live maximum expected 25.0, got %.1f", rollingMax.Value());
      return;
   }

// 10. Test rolling-window expiration
   rollingMax.Reset();

   rollingMax.Append(30.0);
   rollingMax.Append(20.0);
   rollingMax.Append(10.0);

   if(rollingMax.Value() != 30.0)
   {
      PrintFormat("FAIL: Initial rolling maximum expected 30.0, got %.1f", rollingMax.Value());
      return;
   }

   rollingMax.Append(5.0);

   if(rollingMax.Value() != 20.0)
   {
      PrintFormat("FAIL: First expiration expected maximum 20.0, got %.1f", rollingMax.Value());
      return;
   }

   rollingMax.Append(4.0);

   if(rollingMax.Value() != 10.0)
   {
      PrintFormat("FAIL: Second expiration expected maximum 10.0, got %.1f", rollingMax.Value());
      return;
   }

// 11. Test monotonic candidate removal
   rollingMax.Reset();

   rollingMax.Append(10.0);
   rollingMax.Append(20.0);
   rollingMax.Append(30.0);
   rollingMax.Append(5.0);

   if(rollingMax.Value() != 30.0)
   {
      PrintFormat("FAIL: Monotonic candidate removal expected maximum 30.0, got %.1f", rollingMax.Value());
      return;
   }

// 12. Test equal-value candidate replacement
   rollingMax.Reset();

   rollingMax.Append(10.0);
   rollingMax.Append(10.0);
   rollingMax.Append(10.0);
   rollingMax.Append(5.0);

   if(rollingMax.Value() != 10.0)
   {
      PrintFormat("FAIL: Equal-value handling expected maximum 10.0, got %.1f", rollingMax.Value());
      return;
   }

// 13. Test negative values
   rollingMax.Reset();

   rollingMax.Append(-10.0);
   rollingMax.Append(-20.0);
   rollingMax.Append(-30.0);

   if(rollingMax.Value() != -10.0)
   {
      PrintFormat("FAIL: Negative maximum expected -10.0, got %.1f", rollingMax.Value());
      return;
   }

   rollingMax.Append(-40.0);

   if(rollingMax.Value() != -20.0)
   {
      PrintFormat("FAIL: Negative expiration expected -20.0, got %.1f", rollingMax.Value());
      return;
   }

// 14. Test Reset
   rollingMax.Reset();

   if(rollingMax.Value() != 0.0)
   {
      PrintFormat("FAIL: Reset value expected 0.0, got %.1f", rollingMax.Value());
      return;
   }

   if(rollingMax.ReplaceLast(100.0))
   {
      Print("FAIL: ReplaceLast succeeded after Reset.");
      return;
   }

   rollingMax.Append(7.0);

   if(rollingMax.Value() != 7.0)
   {
      PrintFormat("FAIL: Reuse after Reset expected 7.0, got %.1f", rollingMax.Value());
      return;
   }

   Print("SUCCESS: All RollingMax core components passed unit testing!");
}
//+------------------------------------------------------------------+
