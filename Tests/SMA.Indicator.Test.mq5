//+------------------------------------------------------------------+
//|                                           SMA.Indicator.Test.mq5 |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

// Define visual plot properties
#property indicator_label1  "Streaming_SMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#include "..\\Indicators\\SMA.mqh"

// Input parameter to control the window size dynamically
input int InpPeriod = 20; // SMA Period

// Instantiate the encapsulated SMA object globally
SMA g_sma;

// Temporary source struct required by the updated class API
Source g_src;

// Standard MQL5 dynamic indicator plotting array
double g_plotBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
// 1. Configure the SMA instance
   g_sma.SetParameters(InpPeriod);

// 2. Initialize internal components via overridden lifecycle hook
   if(!g_sma.Init())
   {
      Print("FAIL: SMA Component Initialization failed.");
      return(INIT_FAILED);
   }

// 3. Bind raw array to the MT5 indicator core execution engine
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
// Block processing if chart history contains fewer bars than our period
   if(rates_total < InpPeriod)
      return(0);

// Establish historical limit loop boundaries
   int limit = prev_calculated > 0 ? prev_calculated - 1 : 0;

// Handle full recalculation environments cleanly
   if(limit == 0)
   {
      g_sma.Reset(); // Falls back to clearing components
   }

// --- MAIN PIPELINE LOOP ---
   for(int i = limit; i < rates_total && !_StopFlag; i++)
   {
      // Pack the tick/bar context into the expected struct signature
      g_src.time  = time[i];
      g_src.value = close[i];

      // Update the complete indicator state machine
      g_sma.Update(g_src);

      // Read the inverted output index from the container and map to MT5 chart index
      // Since i is ascending here, we always fetch the newest sample (offset 0)
      g_plotBuffer[i] = g_sma.GetValue(0, SMA::MAIN);

      if(i == rates_total - 2)
      {
         for(int j = 0; j < InpPeriod && i - j >= 0; j++)
         {
            PrintFormat("g_plotBuffer[%i] = %f, g_sma.GetValue(%i, SMA::MAIN) = %f, equal? = %s",
                        i - j, g_plotBuffer[i - j], j, g_sma.GetValue(j, SMA::MAIN), g_plotBuffer[i - j] == g_sma.GetValue(j, SMA::MAIN) ? "True" : "False");
         }
      }
      else if(i == rates_total - 1)
      {
         int j = 0;
         Comment(StringFormat("g_plotBuffer[%i] = %f, g_sma.GetValue(%i, SMA::MAIN) = %f, equal? = %s",
                              i - j, g_plotBuffer[i - j], j, g_sma.GetValue(j, SMA::MAIN), g_plotBuffer[i - j] == g_sma.GetValue(j, SMA::MAIN) ? "True" : "False"));
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
