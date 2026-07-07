/**
 * @file SmoothedAverage - Stateless O(1) smoothed average calculation algorithm.
 * @deps None
 * @state Stateless (Calculates one smoothed average step from current value, previous average, and smoothing factor)
 * @io   Current value + previous average + smoothing factor -> Returns next smoothed average double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __SMOOTHED_AVERAGE_MQH__
#define __SMOOTHED_AVERAGE_MQH__

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SmoothedAverage(const double value,
                       const double previous,
                       const double alpha)
{
   return(previous + alpha * (value - previous));
}

#endif // __SMOOTHED_AVERAGE_MQH__
//+------------------------------------------------------------------+
