//+------------------------------------------------------------------+
//|                                     RollingSumSMA.Indicator.Test |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

// Define visual plot properties
#property indicator_label1  "Pipeline_SMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#include "..\\Storage\\BarSeriesBuffer.mqh"
#include "..\\Algorithms\\RollingSum.mqh"

// Input parameter to control the window size dynamically
input int InpPeriod = 20; // Rolling Pipeline Period

// Pipeline Component Objects
CBarSeriesBuffer g_inputBuffer;
CRollingSum      g_rollingSum;

// Standard MQL5 dynamic indicator plotting array
double g_plotBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpPeriod <= 0)
   {
      Print("FAIL: Period must be greater than 0.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(!g_inputBuffer.Init(InpPeriod))
   {
      Print("FAIL: Pipeline input buffer initialization failed.");
      return(INIT_FAILED);
   }

   g_rollingSum.Reset();

   SetIndexBuffer(0, g_plotBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriod - 1);

   PrintFormat("PASS: SMA Pipeline Initialized with Period: %d", InpPeriod);
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
   if(rates_total < InpPeriod)
      return(0);

   int limit = prev_calculated > 0 ? prev_calculated - 1 : 0;

   if(limit == 0)
   {
      g_inputBuffer.Reset();
      g_rollingSum.Reset();
   }

// --- MAIN PIPELINE LOOP ---
   for(int i = limit; i < rates_total && !_StopFlag; i++)
   {
      // 1. Pre-Update Capture: Capture previous value at head (Offset 0) if available
      //double previousValue = 0;
      //g_inputBuffer.At(0, previousValue);

      // 2. Call Update: Let the buffer mutate its internal memory state
      ESeriesEvent event = g_inputBuffer.Update(time[i], close[i]);
      double dropped = !g_inputBuffer.IsFull() ? 0 : g_inputBuffer.DroppedValue();

      // 3. Process actions based on the state transitions
      switch(event)
      {
      case SERIES_FIRST_SAMPLE:
         // No dropped value possible on first item
         g_rollingSum.RollOver();
         g_rollingSum.Update(close[i], 0.0);
         //g_rollingSum.RollOver();
         break;

      case SERIES_APPEND:
         // Read the natively dropped value directly from the new class API
         g_rollingSum.RollOver();
         g_rollingSum.Update(close[i], dropped);
         //g_rollingSum.RollOver();
         break;

      case SERIES_REPLACE_LAST:
         // Roll back the locked sum and replace the old bar value with the new tick value
         g_rollingSum.RollBack();
         g_rollingSum.Update(close[i], dropped);
         break;

      case SERIES_RESET:
         g_rollingSum.Reset();
         g_rollingSum.RollOver();
         g_rollingSum.Update(close[i], 0.0);
         //g_rollingSum.RollOver();
         break;
      }

      // 4. Calculate and store SMA plot values once the window is full
      if(g_inputBuffer.Count() >= InpPeriod)
      {
         g_plotBuffer[i] = g_rollingSum.Value() / InpPeriod;
      }
      else
      {
         g_plotBuffer[i] = EMPTY_VALUE;
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
