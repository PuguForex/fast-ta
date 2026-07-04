/**
 * @file ESeriesEvent - Defines state transitions for tracking bar development across MT5 real-time streaming ticks.
 * @deps None (Pure architectural definition)
 * @state Pure (Immutable enumeration declaration with zero memory overhead or allocation)
 * @io   None -> Exposes compiled state flags (SERIES_FIRST_SAMPLE, SERIES_APPEND, SERIES_REPLACE_LAST, SERIES_RESET)
 * @note AI-assisted code. Independently review and test in a demo environment before live production trading.
 */

#ifndef __ESERIESEVENT_MQH__
#define __ESERIESEVENT_MQH__

enum ESeriesEvent
{
   SERIES_FIRST_SAMPLE,   // First bar
   SERIES_APPEND,         // New bar
   SERIES_REPLACE_LAST,   // Current bar updated (new tick)
   SERIES_RESET           // History reload / reset
};

#endif // __ESERIESEVENT_MQH__
//+------------------------------------------------------------------+