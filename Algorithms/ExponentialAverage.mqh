/**
 * @file ExponentialAverage - Stateless O(1) exponential average calculation algorithm.
 * @deps None
 * @state Stateless (Calculates one exponential average step from current value, previous average, and smoothing factor)
 * @io   Current value + previous average + smoothing factor -> Returns next exponential average double value
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __EXPONENTIAL_AVERAGE_MQH__
#define __EXPONENTIAL_AVERAGE_MQH__

//+------------------------------------------------------------------+
//| ExponentialAverage                                               |
//|                                                                  |
//| PURPOSE                                                          |
//| -------                                                          |
//| Calculate one exponential average step.                          |
//|                                                                  |
//| RESPONSIBILITIES                                                 |
//| ----------------                                                 |
//| • Calculate exponential average                                  |
//|                                                                  |
//| NON-RESPONSIBILITIES                                             |
//| --------------------                                             |
//| • State management                                               |
//| • Series storage                                                 |
//| • Period validation                                              |
//| • Stream event handling                                          |
//+------------------------------------------------------------------+
double ExponentialAverage(const double value,
                          const double previous,
                          const double alpha)
{
   return(previous + alpha * (value - previous));
}

#endif // __EXPONENTIAL_AVERAGE_MQH__
//+------------------------------------------------------------------+
