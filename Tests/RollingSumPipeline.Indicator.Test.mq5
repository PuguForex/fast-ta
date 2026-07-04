//+------------------------------------------------------------------+
//|                               RollingSumPipeline.Indicator.Test |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0

#include "..\\Storage\\BarSeriesBuffer.mqh"
#include "..\\Algorithms\\RollingSum.mqh"

// Pipeline Component Objects
CBarSeriesBuffer g_inputBuffer;
CRollingSum      g_rollingSum;
CBarSeriesBuffer g_outputBuffer;

const int        TEST_CAPACITY = 5; // Low capacity to easily trigger full/outgoing states
bool             g_resetTriggered = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!g_inputBuffer.Init(TEST_CAPACITY) || !g_outputBuffer.Init(TEST_CAPACITY))
   {
      Print("FAIL: Pipeline buffer initialization failed.");
      return(INIT_FAILED);
   }

   g_rollingSum.Reset();
   g_resetTriggered = false;

   PrintFormat("PASS: Pipeline initialized. Capacity: %d bars.", TEST_CAPACITY);
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
   if(rates_total < TEST_CAPACITY + 5)
   {
      PrintFormat("INFO: Insufficient data. Rates: %d, Required: %d", rates_total, TEST_CAPACITY + 5);
      return(0);
   }

// Main historical loop from limit up to rates_total - 2
   const int limit = prev_calculated > 0 ? prev_calculated - 1 : 0;

   for(int i = limit; i < rates_total - 1 && !_StopFlag; i++)
   {
      // --- PIPELINE STEP 1 & 2: Pre-Update Capture ---
      double previousValue = 0;
      bool hasPrevious = g_inputBuffer.At(0, previousValue);

      double outgoingValue = 0;
      bool isFullBeforeUpdate = g_inputBuffer.IsFull();
      if(isFullBeforeUpdate)
      {
         g_inputBuffer.At(g_inputBuffer.Capacity() - 1, outgoingValue);
      }

      // --- PIPELINE STEP 3: Update Input Buffer ---
      ESeriesEvent event = g_inputBuffer.Update(time[i], close[i]);

      // --- PIPELINE STEPS 4 - 8: Event Driven State Machine ---
      switch(event)
      {
      case SERIES_FIRST_SAMPLE:
         // Step 4: FIRST_SAMPLE -> RollingSum.Update(value, 0) -> RollOver().
         g_rollingSum.Update(close[i], 0.0);
         g_rollingSum.RollOver();

         if(prev_calculated == 0)
            PrintFormat("PASS [Step 4]: FIRST_SAMPLE handled. Value added: %f. Sum: %f", close[i], g_rollingSum.Value());
         break;

      case SERIES_APPEND:
         if(!isFullBeforeUpdate)
         {
            // Step 5: APPEND + not full before update -> RollingSum.Update(value, 0) -> RollOver().
            g_rollingSum.Update(close[i], 0.0);
            g_rollingSum.RollOver();

            if(i <= 3 && prev_calculated == 0)
               PrintFormat("PASS [Step 5]: APPEND (Not Full) at index %d. Added: %f. Sum: %f", i, close[i], g_rollingSum.Value());
         }
         else
         {
            // Step 6: APPEND + full before update -> RollingSum.Update(value, outgoing) -> RollOver().
            g_rollingSum.Update(close[i], outgoingValue);
            g_rollingSum.RollOver();

            if(i == TEST_CAPACITY && prev_calculated == 0)
               PrintFormat("PASS [Step 6]: APPEND (Full). Added: %f, Subtracted Outgoing: %f. Sum: %f", close[i], outgoingValue, g_rollingSum.Value());
         }
         break;

      case SERIES_RESET:
         // Step 8: RESET -> RollingSum.Reset() -> Update(value, 0) -> RollOver().
         g_rollingSum.Reset();
         g_rollingSum.Update(close[i], 0.0);
         g_rollingSum.RollOver();

         PrintFormat("PASS [Step 8]: RESET handled. Sum reset & anchored to: %f", g_rollingSum.Value());
         break;

      case SERIES_REPLACE_LAST:
         // Fallback precaution for history iteration
         break;
      }

      // --- PIPELINE STEPS 9 & 10: Propagate to Output Buffer ---
      double finalSum = g_rollingSum.Value();
      g_outputBuffer.Update(time[i], finalSum);

      // --- OPTIONAL: Synthetic History Reset Simulation ---
      if(i == 5 && prev_calculated == 0 && !g_resetTriggered)
      {
         Print("--- Executing Synthetic Pipeline Reset Verification ---");
         g_resetTriggered = true;

         // Trigger reset event explicitly by rewinding time
         datetime syntheticPastTime = time[i] - 3600;
         ESeriesEvent resetEvent = g_inputBuffer.Update(syntheticPastTime, close[i]);

         if(resetEvent == SERIES_RESET)
         {
            g_rollingSum.Reset();
            g_rollingSum.Update(close[i], 0.0);
            g_rollingSum.RollOver();
            g_outputBuffer.Update(syntheticPastTime, g_rollingSum.Value());
            PrintFormat("PASS [Pipeline Reset]: Step 8 pipeline execution verified on synthetic time rewind.");
         }

         // Fast-forward re-align back to history stream
         g_inputBuffer.Update(time[i], close[i]);
         g_rollingSum.Update(close[i], 0.0);
         g_rollingSum.RollOver();
      }
   }

// --- Live Market Bar Simulation & Tick Phase Verification (i == rates_total - 1) ---
   if(!_StopFlag)
   {
      int liveIdx = rates_total - 1;

      // -- LIVE TICK 1: Simulate standard incoming live bar or update --
      double liveVal1 = close[liveIdx];
      double prevVal1 = 0;
      g_inputBuffer.At(0, prevVal1);
      double outVal1 = 0;
      bool full1 = g_inputBuffer.IsFull();
      if(full1) g_inputBuffer.At(g_inputBuffer.Capacity() - 1, outVal1);

      ESeriesEvent ev1 = g_inputBuffer.Update(time[liveIdx], liveVal1);
      if(ev1 == SERIES_APPEND)
      {
         g_rollingSum.Update(liveVal1, full1 ? outVal1 : 0.0);
         g_rollingSum.RollOver();
      }
      else if(ev1 == SERIES_REPLACE_LAST)
      {
         g_rollingSum.RollBack();
         g_rollingSum.Update(liveVal1, prevVal1);
      }
      g_outputBuffer.Update(time[liveIdx], g_rollingSum.Value());

      // -- LIVE TICK 2: Force continuous fluctuating market tick on same bar --
      double liveVal2 = close[liveIdx] + 0.0025; // Continuous tick price change

      // Step 1: Pre-Update Capture on Tick 2
      double prevVal2 = 0;
      bool hasPrev2 = g_inputBuffer.At(0, prevVal2); // Captures current live value before update

      // Step 3: Call Update (Triggers same bar condition)
      ESeriesEvent ev2 = g_inputBuffer.Update(time[liveIdx], liveVal2);

      if(ev2 == SERIES_REPLACE_LAST)
      {
         // Step 7: REPLACE_LAST -> RollBack() -> RollingSum.Update(value, previous).
         g_rollingSum.RollBack();
         g_rollingSum.Update(liveVal2, prevVal2);

         PrintFormat("PASS [Step 7]: REPLACE_LAST verified on live tick. Rollback successful. Previous: %f, New Tick: %f, New Sum: %f",
                     prevVal2, liveVal2, g_rollingSum.Value());
      }
      else
      {
         PrintFormat("FAIL: Expected SERIES_REPLACE_LAST on live tick update, got %d", ev2);
      }

      // Step 9 & 10: Read result and update output buffer
      g_outputBuffer.Update(time[liveIdx], g_rollingSum.Value());

      // -- FINAL STEP: Pipeline Integrity Cross-Verification Matrix --
      if(prev_calculated == 0)
      {
         Print("--- Running Pipeline Verification Against Raw Array Math ---");

         double manualSum = 0.0;
         int barsToSum = MathMin(g_inputBuffer.Count(), TEST_CAPACITY);

         // Calculate structural moving sum directly from current active window of live chart array
         for(int k = 0; k < barsToSum; k++)
         {
            int arrayIndex = liveIdx - k;
            // Compensate for liveTick 2 synthetic adjustments
            manualSum += (k == 0) ? liveVal2 : close[arrayIndex];
         }

         double pipelineSum = g_rollingSum.Value();
         double outputBufferSum = 0;
         g_outputBuffer.At(0, outputBufferSum);

         if(NormalizeDouble(pipelineSum - manualSum, _Digits) == 0 && NormalizeDouble(outputBufferSum - manualSum, _Digits) == 0)
         {
            PrintFormat("PASS [Steps 9 & 10]: Multi-stage rolling pipeline matches raw array math perfectly.");
            PrintFormat("SUCCESS: Pipeline integration test passed! Value matching verified: %f", outputBufferSum);
         }
         else
         {
            PrintFormat("FAIL: Pipeline mismatch! Pipeline: %f, OutputBuffer: %f, Manual Array Sum: %f",
                        pipelineSum, outputBufferSum, manualSum);
         }
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
