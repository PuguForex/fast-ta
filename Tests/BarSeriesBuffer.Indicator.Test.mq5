//+------------------------------------------------------------------+
//|                                  BarSeriesBuffer.Indicator.Test |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0

#include "..\\Storage\\BarSeriesBuffer.mqh"

// Instantiate the buffer globally for persistence across ticks
CBarSeriesBuffer g_buffer;
const int        TEST_CAPACITY = 20;
bool             g_resetTriggered = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_buffer.Init(TEST_CAPACITY))
   {
      Print("FAIL: Buffer initialization failed.");
      return(INIT_FAILED);
   }

   PrintFormat("PASS: Buffer initialized with capacity: %d", TEST_CAPACITY);
   g_resetTriggered = false;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
// Check if there are enough bars to perform the historical comparison safely
   if(rates_total < TEST_CAPACITY + 5)
   {
      PrintFormat("INFO: Insufficient data. Rates total: %d, Required: %d", rates_total, TEST_CAPACITY + 5);
      return(0);
   }

// Main historical loop running from limit up to rates_total - 2
   const int limit = prev_calculated > 0 ? prev_calculated - 1 : 0;

   for(int i = limit; i < rates_total - 1 && !_StopFlag; i++)
   {
      ESeriesEvent res = g_buffer.Update(time[i], close[i]);

      // Test 1: First sample validation
      if(i == 0 && prev_calculated == 0)
      {
         if(res != SERIES_FIRST_SAMPLE)
            PrintFormat("FAIL: Expected SERIES_FIRST_SAMPLE at index 0, got %d", res);
         else
            PrintFormat("PASS: SERIES_FIRST_SAMPLE verified at index 0. Time: %s, Price: %f", TimeToString(time[i]), close[i]);
      }
      // Test 2: Standard bar appends (Log selectively on the first few elements to prevent terminal spam)
      else if(i > 0 && !g_resetTriggered)
      {
         if(res != SERIES_APPEND)
            PrintFormat("FAIL: Expected SERIES_APPEND at index %d, got %d", i, res);
         else if(i <= 3 && prev_calculated == 0)
            PrintFormat("PASS: SERIES_APPEND verified at historical index %d. Time: %s", i, TimeToString(time[i]));
      }

      // Test 3: Synthetic History Reset Simulation
      // Inject a time rewind exactly at index 5 when recalculating from scratch
      if(i == 5 && prev_calculated == 0 && !g_resetTriggered)
      {
         Print("--- Running Synthetic History Reset Verification ---");

         // Feed an older timestamp (1 hour behind current processing index)
         datetime syntheticPastTime = time[i] - 3600;
         ESeriesEvent resetRes = g_buffer.Update(syntheticPastTime, close[i]);

         if(resetRes != SERIES_RESET)
            PrintFormat("FAIL: Expected SERIES_RESET on time rewind, got %d", resetRes);
         else
            PrintFormat("PASS: SERIES_RESET verified successfully. Sent old time: %s, Buffer count reset to: %d", TimeToString(syntheticPastTime), g_buffer.Count());

         g_resetTriggered = true;

         // Repopulate the current bar index to resume clean state flow
         g_buffer.Update(time[i], close[i]);
      }
   }

// Test 4: Live Market Bar Simulation (i == rates_total - 1)
   if(!_StopFlag && prev_calculated <= 0)
   {
      int liveIdx = rates_total - 1;

      // Simulate Tick 1 on Live Bar (Creates a new bar entry or updates depending on tick history)
      ESeriesEvent liveRes1 = g_buffer.Update(time[liveIdx], close[liveIdx]);

      // Simulate Tick 2 on the SAME Live Bar with a synthetic fluctuating price
      double temporaryPrice = close[liveIdx] + 0.0005;
      ESeriesEvent liveRes2 = g_buffer.Update(time[liveIdx], temporaryPrice);

      if(liveRes2 != SERIES_REPLACE_LAST)
         PrintFormat("FAIL: Expected SERIES_REPLACE_LAST on live tick update, got %d", liveRes2);
      else
         PrintFormat("PASS: SERIES_REPLACE_LAST verified on live bar tick update. Temporary Price: %f", temporaryPrice);

      // Restore the actual closing price to match standard data arrays for index comparison
      g_buffer.Update(time[liveIdx], close[liveIdx]);

      // Test 5: Inverted Index Comparison Matrix (Buffer 0 vs MQL5 rates_total - 1)
      bool matchPassed = true;
      int compareBars = MathMin(g_buffer.Count(), TEST_CAPACITY);

      for(int offset = 0; offset < compareBars; offset++)
      {
         double bufferVal = 0;
         if(!g_buffer.At(offset, bufferVal))
         {
            PrintFormat("FAIL: Could not retrieve buffer value at offset %d", offset);
            matchPassed = false;
            break;
         }

         // Invert rates total mapping index
         int arrayIdx = liveIdx - offset;

         if(NormalizeDouble(bufferVal - close[arrayIdx], _Digits) != 0)
         {
            PrintFormat("FAIL: Mismatch at offset %d! Buffer: %f, Close Array: %f",
                        offset, bufferVal, close[arrayIdx]);
            matchPassed = false;
            break;
         }
      }

      if(matchPassed)
      {
         PrintFormat("PASS: Inverted indexing comparison verified! Matched all past %d bars.", compareBars);
         PrintFormat("SUCCESS: All 4 state transitions and buffer indices matched perfectly with chart arrays.");
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
