//+------------------------------------------------------------------+
//|                                     RollingMinMax.Script.Test.mq5 |
//+------------------------------------------------------------------+
#property script_show_inputs

#include "..\\Algorithms\\RollingMin.mqh"
#include "..\\Algorithms\\RollingMax.mqh"

//+------------------------------------------------------------------+
//| Compare                                                           |
//+------------------------------------------------------------------+
bool Equal(const double left,
           const double right)
{
   return(MathAbs(left - right) < 1e-10);
}

//+------------------------------------------------------------------+
//| Brute Force Minimum                                               |
//+------------------------------------------------------------------+
double BruteMin(const double &values[],
                const int count)
{
   double result = values[0];

   for(int i = 1; i < count; i++)
      result = MathMin(result, values[i]);

   return(result);
}

//+------------------------------------------------------------------+
//| Brute Force Maximum                                               |
//+------------------------------------------------------------------+
double BruteMax(const double &values[],
                const int count)
{
   double result = values[0];

   for(int i = 1; i < count; i++)
      result = MathMax(result, values[i]);

   return(result);
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("--- Starting RollingMinMax Isolated Test ---");

// 1. Test Initialization
   CRollingMin rollingMin;
   CRollingMax rollingMax;

   if(rollingMin.Init(0) || rollingMax.Init(0))
   {
      Print("FAIL: Initialization succeeded with zero capacity.");
      return;
   }

   if(!rollingMin.Init(3) || !rollingMax.Init(3))
   {
      Print("FAIL: Initialization failed.");
      return;
   }

   if(rollingMin.Value() != 0.0 || rollingMax.Value() != 0.0)
   {
      Print("FAIL: Invalid initial state.");
      return;
   }

// 2. Test Warmup
   rollingMin.Append(30.0);
   rollingMax.Append(30.0);

   if(rollingMin.Value() != 30.0 || rollingMax.Value() != 30.0)
   {
      Print("FAIL: First warmup value incorrect.");
      return;
   }

   rollingMin.Append(10.0);
   rollingMax.Append(10.0);

   if(rollingMin.Value() != 10.0 || rollingMax.Value() != 30.0)
   {
      Print("FAIL: Second warmup value incorrect.");
      return;
   }

   rollingMin.Append(20.0);
   rollingMax.Append(20.0);

   if(rollingMin.Value() != 10.0 || rollingMax.Value() != 30.0)
   {
      Print("FAIL: Full warmup window incorrect.");
      return;
   }

// 3. Test Domination
   rollingMin.Reset();
   rollingMax.Reset();

   rollingMin.Append(30.0);
   rollingMax.Append(10.0);

   rollingMin.Append(20.0);
   rollingMax.Append(20.0);

   rollingMin.Append(10.0);
   rollingMax.Append(30.0);

   rollingMin.Append(25.0);
   rollingMax.Append(15.0);

   if(rollingMin.Value() != 10.0 || rollingMax.Value() != 30.0)
   {
      Print("FAIL: Monotonic domination handling incorrect.");
      return;
   }

// 4. Test Expiry Boundaries
   rollingMin.Reset();
   rollingMax.Reset();

   rollingMin.Append(10.0);
   rollingMax.Append(30.0);

   rollingMin.Append(20.0);
   rollingMax.Append(20.0);

   rollingMin.Append(30.0);
   rollingMax.Append(10.0);

   if(rollingMin.Value() != 10.0 || rollingMax.Value() != 30.0)
   {
      Print("FAIL: Pre-expiry boundary incorrect.");
      return;
   }

   rollingMin.Append(40.0);
   rollingMax.Append(5.0);

   if(rollingMin.Value() != 20.0 || rollingMax.Value() != 20.0)
   {
      Print("FAIL: First expiry boundary incorrect.");
      return;
   }

   rollingMin.Append(50.0);
   rollingMax.Append(4.0);

   if(rollingMin.Value() != 30.0 || rollingMax.Value() != 10.0)
   {
      Print("FAIL: Second expiry boundary incorrect.");
      return;
   }

// 5. Test Repeated Arbitrary ReplaceLast
   rollingMin.Reset();
   rollingMax.Reset();

   rollingMin.Append(10.0);
   rollingMax.Append(10.0);

   rollingMin.Append(20.0);
   rollingMax.Append(20.0);

   rollingMin.Append(30.0);
   rollingMax.Append(30.0);

   if(!rollingMin.ReplaceLast(5.0) ||
         !rollingMax.ReplaceLast(5.0))
   {
      Print("FAIL: First ReplaceLast execution failed.");
      return;
   }

   if(rollingMin.Value() != 5.0 || rollingMax.Value() != 20.0)
   {
      Print("FAIL: First ReplaceLast result incorrect.");
      return;
   }

   rollingMin.ReplaceLast(40.0);
   rollingMax.ReplaceLast(40.0);

   if(rollingMin.Value() != 10.0 || rollingMax.Value() != 40.0)
   {
      Print("FAIL: Second ReplaceLast result incorrect.");
      return;
   }

   rollingMin.ReplaceLast(15.0);
   rollingMax.ReplaceLast(15.0);

   if(rollingMin.Value() != 10.0 || rollingMax.Value() != 20.0)
   {
      Print("FAIL: Third ReplaceLast result incorrect.");
      return;
   }

   rollingMin.ReplaceLast(-5.0);
   rollingMax.ReplaceLast(50.0);

   if(rollingMin.Value() != -5.0 || rollingMax.Value() != 50.0)
   {
      Print("FAIL: Fourth ReplaceLast result incorrect.");
      return;
   }

// 6. Test Next Append Commit After Replacement
   rollingMin.Reset();
   rollingMax.Reset();

   rollingMin.Append(10.0);
   rollingMax.Append(10.0);

   rollingMin.Append(20.0);
   rollingMax.Append(20.0);

   rollingMin.Append(30.0);
   rollingMax.Append(30.0);

   rollingMin.ReplaceLast(5.0);
   rollingMax.ReplaceLast(50.0);

   rollingMin.Append(40.0);
   rollingMax.Append(40.0);

   if(rollingMin.Value() != 5.0 || rollingMax.Value() != 50.0)
   {
      Print("FAIL: Replaced live value was not committed on next Append.");
      return;
   }

   rollingMin.Append(60.0);
   rollingMax.Append(5.0);

   if(rollingMin.Value() != 5.0 || rollingMax.Value() != 50.0)
   {
      Print("FAIL: Committed replacement state expired too early.");
      return;
   }

   rollingMin.Append(70.0);
   rollingMax.Append(4.0);

   if(rollingMin.Value() != 40.0 || rollingMax.Value() != 40.0)
   {
      Print("FAIL: Committed replacement expiry incorrect.");
      return;
   }

// 7. Test Reset
   rollingMin.Reset();
   rollingMax.Reset();

   if(rollingMin.Value() != 0.0 || rollingMax.Value() != 0.0)
   {
      Print("FAIL: Reset did not restore empty state.");
      return;
   }

   if(rollingMin.ReplaceLast(10.0) ||
         rollingMax.ReplaceLast(10.0))
   {
      Print("FAIL: ReplaceLast succeeded after Reset.");
      return;
   }

   rollingMin.Append(7.0);
   rollingMax.Append(7.0);

   if(rollingMin.Value() != 7.0 || rollingMax.Value() != 7.0)
   {
      Print("FAIL: Reuse after Reset incorrect.");
      return;
   }

// 8. Test Period 1
   CRollingMin periodOneMin;
   CRollingMax periodOneMax;

   if(!periodOneMin.Init(1) || !periodOneMax.Init(1))
   {
      Print("FAIL: Period 1 initialization failed.");
      return;
   }

   periodOneMin.Append(10.0);
   periodOneMax.Append(10.0);

   if(periodOneMin.Value() != 10.0 || periodOneMax.Value() != 10.0)
   {
      Print("FAIL: Period 1 first value incorrect.");
      return;
   }

   periodOneMin.ReplaceLast(20.0);
   periodOneMax.ReplaceLast(20.0);

   if(periodOneMin.Value() != 20.0 || periodOneMax.Value() != 20.0)
   {
      Print("FAIL: Period 1 ReplaceLast incorrect.");
      return;
   }

   periodOneMin.Append(30.0);
   periodOneMax.Append(30.0);

   if(periodOneMin.Value() != 30.0 || periodOneMax.Value() != 30.0)
   {
      Print("FAIL: Period 1 Append incorrect.");
      return;
   }

// 9. Compare Against Brute-Force Window Min/Max
   const int period = 5;

   CRollingMin testMin;
   CRollingMax testMax;

   if(!testMin.Init(period) || !testMax.Init(period))
   {
      Print("FAIL: Brute-force comparison initialization failed.");
      return;
   }

   double source[] =
   {
      12.0, -5.0, 8.0, 8.0, 30.0,
      4.0, -10.0, 25.0, 7.0, 40.0,
      3.0, 3.0, -20.0, 50.0, 1.0
   };

   double window[];
   ArrayResize(window, period);

   int windowCount = 0;

   for(int i = 0; i < ArraySize(source); i++)
   {
      testMin.Append(source[i]);
      testMax.Append(source[i]);

      if(windowCount < period)
      {
         window[windowCount] = source[i];
         ++windowCount;
      }
      else
      {
         for(int j = 1; j < period; j++)
            window[j - 1] = window[j];

         window[period - 1] = source[i];
      }

      double expectedMin = BruteMin(window, windowCount);
      double expectedMax = BruteMax(window, windowCount);

      double actualMin = testMin.Value();
      double actualMax = testMax.Value();

      if(!Equal(actualMin, expectedMin) ||
            !Equal(actualMax, expectedMax))
      {
         PrintFormat("FAIL: Brute-force mismatch at index %d. Expected Min=%.1f, Actual Min=%.1f, Expected Max=%.1f, Actual Max=%.1f",
                     i,
                     expectedMin,
                     actualMin,
                     expectedMax,
                     actualMax);
         return;
      }
   }

// 10. Brute-Force Stress Test with Interleaved Append and ReplaceLast
   int periods[] = {1, 2, 3, 5, 20};

   MathSrand(123456);

   for(int p = 0; p < ArraySize(periods); p++)
   {
      int period = periods[p];

      CRollingMin stressMin;
      CRollingMax stressMax;

      if(!stressMin.Init(period) || !stressMax.Init(period))
      {
         PrintFormat("FAIL: Stress test initialization failed for period %d.", period);
         return;
      }

      double window[];
      ArrayResize(window, period);

      int windowCount = 0;

      for(int operation = 0; operation < 10000; operation++)
      {
         bool append = (windowCount == 0 || MathRand() % 3 == 0);

         double value = (double)(MathRand() % 20001 - 10000) / 100.0;

         if(append)
         {
            stressMin.Append(value);
            stressMax.Append(value);

            if(windowCount < period)
            {
               window[windowCount] = value;
               ++windowCount;
            }
            else
            {
               for(int i = 1; i < period; i++)
                  window[i - 1] = window[i];

               window[period - 1] = value;
            }
         }
         else
         {
            if(!stressMin.ReplaceLast(value) ||
                  !stressMax.ReplaceLast(value))
            {
               PrintFormat("FAIL: Stress ReplaceLast failed. Period=%d, Operation=%d",
                           period, operation);
               return;
            }

            window[windowCount - 1] = value;
         }

         double expectedMin = BruteMin(window, windowCount);
         double expectedMax = BruteMax(window, windowCount);

         double actualMin = stressMin.Value();
         double actualMax = stressMax.Value();

         if(!Equal(actualMin, expectedMin) ||
               !Equal(actualMax, expectedMax))
         {
            PrintFormat("FAIL: Stress mismatch. Period=%d, Operation=%d, Type=%s, Value=%.2f, Expected Min=%.2f, Actual Min=%.2f, Expected Max=%.2f, Actual Max=%.2f",
                        period,
                        operation,
                        append ? "Append" : "ReplaceLast",
                        value,
                        expectedMin,
                        actualMin,
                        expectedMax,
                        actualMax);
            return;
         }
      }

      PrintFormat("PASS: Stress test completed for period %d.", period);
   }

   Print("SUCCESS: All RollingMinMax isolated tests passed!");
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
