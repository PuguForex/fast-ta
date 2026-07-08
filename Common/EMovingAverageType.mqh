/**
 * @file EMovingAverageType - Defines supported moving average calculation types.
 * @deps None
 * @state Stateless (Compile-time enumeration of supported moving average types)
 * @io   Moving average type identifier -> Used for indicator calculation method selection
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __EMOVING_AVERAGE_TYPE_MQH__
#define __EMOVING_AVERAGE_TYPE_MQH__

enum EMovingAverageType
{
   MA_SIMPLE,
   MA_EXPONENTIAL,
   MA_SMOOTHED,
   MA_LINEAR_WEIGHTED
};

#endif // __EMOVING_AVERAGE_TYPE_MQH__
//+------------------------------------------------------------------+
