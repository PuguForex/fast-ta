//+------------------------------------------------------------------+
//|                                    Stochastic.Indicator.Test.mq5 |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2

// Define visual plot properties
#property indicator_label1  "Streaming_K"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "Streaming_D"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#include "..\\Indicators\\Stochastic.mqh"

// Input parameters
input int                InpKPeriod       = 5;         // K Period
input int                InpDPeriod       = 3;         // D Period
input int                InpSlowingPeriod = 3;         // Slowing Period
input EMovingAverageType InpMAType        = MA_SIMPLE; // Signal MA Type

// Instantiate the encapsulated Stochastic object globally
Stochastic g_stochastic;

// Temporary source struct required by the updated class API
Source g_src;

// Standard MQL5 dynamic indicator plotting arrays
double g_mainBuffer[];
double g_signalBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
// 1. Configure the Stochastic instance
   g_stochastic.SetParameters(InpKPeriod,
                              InpDPeriod,
                              InpSlowingPeriod,
                              InpMAType);

// 2. Initialize internal components via overridden lifecycle hook
   if(!g_stochastic.Init())
   {
      Print("FAIL: Stochastic Component Initialization failed.");
      return(INIT_FAILED);
   }

// 3. Bind raw arrays to the MT5 indicator core execution engine
   SetIndexBuffer(0, g_mainBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, g_signalBuffer, INDICATOR_DATA);

   PlotIndexSetInteger(0,
                       PLOT_DRAW_BEGIN,
                       InpKPeriod + InpSlowingPeriod - 2);

   PlotIndexSetInteger(1,
                       PLOT_DRAW_BEGIN,
                       InpKPeriod + InpSlowingPeriod + InpDPeriod - 3);

   PrintFormat("PASS: Stochastic Pipeline Initialized with K: %d, D: %d, Slowing: %d",
               InpKPeriod,
               InpDPeriod,
               InpSlowingPeriod);

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
// Block processing if chart history contains fewer bars than our K period
   if(rates_total < InpKPeriod)
      return(0);

// Establish historical limit loop boundaries
   int limit = prev_calculated > 0 ? prev_calculated - 1 : 0;

// Handle full recalculation environments cleanly
   if(limit == 0)
   {
      g_stochastic.Reset(); // Falls back to clearing components
   }

// --- MAIN PIPELINE LOOP ---
   for(int i = limit; i < rates_total && !_StopFlag; i++)
   {
      // Pack the OHLC bar context into the expected struct signature
      g_src = Source::From(open[i],
                           high[i],
                           low[i],
                           close[i],
                           time[i]);

      // Update the complete indicator state machine
      g_stochastic.Update(g_src);

      // Read both output lines from the container and map to MT5 chart indexes
      // Since i is ascending here, we always fetch the newest sample (offset 0)
      g_mainBuffer[i]   = g_stochastic.GetValue(0, Stochastic::MAIN);
      g_signalBuffer[i] = g_stochastic.GetValue(0, Stochastic::SIGNAL);

      if(i == rates_total - 2)
      {
         for(int j = 0; j < InpKPeriod && i - j >= 0; j++)
         {
            PrintFormat("K: g_mainBuffer[%i] = %f, g_stochastic.GetValue(%i, Stochastic::MAIN) = %f, equal? = %s",
                        i - j,
                        g_mainBuffer[i - j],
                        j,
                        g_stochastic.GetValue(j, Stochastic::MAIN),
                        g_mainBuffer[i - j] == g_stochastic.GetValue(j, Stochastic::MAIN) ? "True" : "False");

            PrintFormat("D: g_signalBuffer[%i] = %f, g_stochastic.GetValue(%i, Stochastic::SIGNAL) = %f, equal? = %s",
                        i - j,
                        g_signalBuffer[i - j],
                        j,
                        g_stochastic.GetValue(j, Stochastic::SIGNAL),
                        g_signalBuffer[i - j] == g_stochastic.GetValue(j, Stochastic::SIGNAL) ? "True" : "False");
         }
      }
      else if(i == rates_total - 1)
      {
         int j = 0;

         Comment(StringFormat("K: g_mainBuffer[%i] = %f, g_stochastic.GetValue(%i, Stochastic::MAIN) = %f, equal? = %s\nD: g_signalBuffer[%i] = %f, g_stochastic.GetValue(%i, Stochastic::SIGNAL) = %f, equal? = %s",
                              i - j,
                              g_mainBuffer[i - j],
                              j,
                              g_stochastic.GetValue(j, Stochastic::MAIN),
                              g_mainBuffer[i - j] == g_stochastic.GetValue(j, Stochastic::MAIN) ? "True" : "False",
                              i - j,
                              g_signalBuffer[i - j],
                              j,
                              g_stochastic.GetValue(j, Stochastic::SIGNAL),
                              g_signalBuffer[i - j] == g_stochastic.GetValue(j, Stochastic::SIGNAL) ? "True" : "False"));
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
