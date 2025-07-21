//+------------------------------------------------------------------+
//|                                                PriceAction.mq4   |
//|                Modular Price Action Events Indicator             |
//+------------------------------------------------------------------+


//--- constants for states
enum TrendState {
   NO_TREND = 0,
   UP_TREND = 1,
   UP_TREND_RETRACEMENT = 2,
   DOWN_TREND = 3,
   DOWN_TREND_RETRACEMENT = 4,
};

enum PeakState {
   NO_PEAK = 0,
   LOCAL_HIGH_PEAK = 1,
   LOCAL_LOW_PEAK = 2,
   HIGHER_HIGH_PEAK = 3,
   LOWER_LOW_PEAK = 4
};

struct PaResults
{
   int errorCode; // 0 - no error, other values indicate errors
   int trendState;
   PeakState prevBarPeakState;
};

struct PrevPeaks 
{
   int peakInd1;
   double peakClose1; //last
   PeakState peakState1;
   int peakInd2;
   double peakClose2; // before last
   PeakState peakState2;
};

//+------------------------------------------------------------------+
//| Setup                                               
//+------------------------------------------------------------------+
input double TrendMargin = 0; // points
input bool verbose = true;

//--- internal state variables
TrendState TrendBuffer[];
PeakState PeakBuffer[];

int PaInit()
{
   PaResults results;
   results.errorCode = 0; // No error
   results.trendState = NO_TREND;
   results.prevBarPeakState = NO_PEAK;

   if (Bars < 3) return (0);
   
   // Clean up all objects before redrawing
   //CleanPeakLines();
   //CleanPeakLabels();

   ArrayResize(TrendBuffer, Bars);
   ArraySetAsSeries(TrendBuffer, true);
   ArrayResize(PeakBuffer, Bars);
   ArraySetAsSeries(PeakBuffer, true);

   for(int i=Bars-2; i>=0; i--)
   {
      //if (i < Bars - 1) // Only process if there's a next bar
      results = ProcessBar(i);
      if (results.errorCode != 0) 
      {
         return 0; // Return error code if any
      }
   }

   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
PaResults PaProcessBars()
{
   PaResults results;
  
   // Clean up all objects before redrawing
   //CleanPeakLines();
   //CleanPeakLabels();

   static datetime lastTime = 0;
   if (lastTime == Time[0]) 
   {
      //if(verbose) Print("ProcessBar: Skipping bar i=", 0, " because it's the same as last processed bar");
      results.errorCode = 1; // Skip if same time as last processed
      return results; // Skip if same time as last processed
   }
   lastTime = Time[0];

   ArrayResize(TrendBuffer, Bars);
   ArraySetAsSeries(TrendBuffer, true);
   ArrayResize(PeakBuffer, Bars);
   ArraySetAsSeries(PeakBuffer, true);

   results = ProcessBar(1);

   return results;
}

//+------------------------------------------------------------------+
//| Process logic for a single bar                                   |
//+------------------------------------------------------------------+
PaResults ProcessBar(int i)
{
   PaResults results;
   results.errorCode = 0; // Error code 1 indicates processing error
   results.trendState = NO_TREND;
   results.prevBarPeakState = NO_PEAK;

   if(verbose) Print("ProcessBar i=", i, ", Time=", TimeToString(Time[i], TIME_DATE | TIME_MINUTES));

   PeakState peak_state = NO_PEAK;

   TrendState lastBarDirection = DetectBarDirection(Close[i+1], Close[i]);

   TrendBuffer[i] = DetectTrendState(i, TrendBuffer[i+1], lastBarDirection);

   // Peak detection logic
   peak_state = DetectPeakState(i, TrendBuffer[i+1], TrendBuffer[i]);
   if(peak_state != NO_PEAK)
   {
      VisualizePeakOverlay(i+1, peak_state);
      // DrawPeakLines(i);
   }

   // Buffers
   PeakBuffer[i+1] = peak_state;

   results.trendState = TrendBuffer[i];
   results.prevBarPeakState = peak_state;
   
   if(verbose) Print("ProcessBar i=", i, ", TrendBuffer[", i, "]=", GetTrendDescription((TrendState)TrendBuffer[i]), 
                     ", PeakBuffer[", i+1, "]=", GetPeakDescription((PeakState)PeakBuffer[i+1]));

   return results;
}

//+------------------------------------------------------------------+
//| Detect the basic trend between two closes                        |
//+------------------------------------------------------------------+
TrendState DetectBarDirection(double prevClose, double currClose)
{
   if(currClose > prevClose + Point*TrendMargin)
   {
      if(verbose) Print("DetectBarDirection UP");
      return UP_TREND;
   }
   else if(currClose < prevClose - Point*TrendMargin)
   {
      if(verbose) Print("DetectBarDirection DOWN");
      return DOWN_TREND;
   }
   else
   {
      if(verbose) Print("DetectBarDirection NO Direction");
      return NO_TREND;
   }
}

//+------------------------------------------------------------------+
//| Detect the basic trend between two closes                        |
//+------------------------------------------------------------------+
PrevPeaks GetPrevLowHighPeaks(int i, int limit)
{   
   PrevPeaks peaks;
   peaks.peakClose1 = -1;
   peaks.peakClose2 = -1;
   peaks.peakState1 = NO_PEAK;
   peaks.peakState2 = NO_PEAK;
   peaks.peakInd1 = -1;
   peaks.peakInd2 = -1;

   int peakCount = 0;

   for(int p=i+1; p<=limit; p++)
   {
      if (p < Bars - 1) // Only process if there's a next bar
      {
         if(PeakBuffer[p] == NO_PEAK)
            continue; // Skip if no peak
         
         peakCount++;

         if(peaks.peakState1 == NO_PEAK)
         {
            peaks.peakInd1 = p;
            peaks.peakClose1 = Close[p];
            peaks.peakState1 = (PeakState)PeakBuffer[p];
            //if(verbose) Print("GetPrevLowHighPeaks found first peak at index ", p, ", state=", GetPeakDescription(peaks.peakState1), ", close=", peaks.peakClose1);
         }
         else if((peaks.peakState1 == LOCAL_LOW_PEAK || peaks.peakState1 == LOWER_LOW_PEAK) && (PeakBuffer[p] == LOCAL_HIGH_PEAK || PeakBuffer[p] == HIGHER_HIGH_PEAK))
         {
            peaks.peakInd2 = p;
            peaks.peakClose2 = Close[p];
            peaks.peakState2 = (PeakState)PeakBuffer[p];
            //if(verbose) Print("GetPrevLowHighPeaks found second peak at index ", p, ", state=", GetPeakDescription(peaks.peakState2), ", close=", peaks.peakClose2);
            break;
         }
         else if((peaks.peakState1 == LOCAL_HIGH_PEAK || peaks.peakState1 == HIGHER_HIGH_PEAK) && (PeakBuffer[p] == LOCAL_LOW_PEAK || PeakBuffer[p] == LOWER_LOW_PEAK))
         {
            peaks.peakInd2 = p;
            peaks.peakClose2 = Close[p];
            peaks.peakState2 = (PeakState)PeakBuffer[p];
            //if(verbose) Print("GetPrevLowHighPeaks found second peak at index ", p, ", state=", GetPeakDescription(peaks.peakState2), ", close=", peaks.peakClose2);
            break;
         }
         
      }
   }   

   return peaks;
}
//+------------------------------------------------------------------+
//| Get peak state description          |
//+------------------------------------------------------------------+
string GetPeakDescription(PeakState peakState)
{
   switch(peakState)
   {
      case NO_PEAK:
         return "NO_PEAK";
      case LOCAL_HIGH_PEAK:
         return "LOCAL_HIGH_PEAK";     
      case LOCAL_LOW_PEAK:
         return "LOCAL_LOW_PEAK";
      case HIGHER_HIGH_PEAK:
         return "HIGHER_HIGH_PEAK";
      case LOWER_LOW_PEAK:
         return "LOWER_LOW_PEAK";
      default:
         return "UNKNOWN_PEAK_STATE";
   }
}
//+------------------------------------------------------------------+
//| Get trend state description          |
//+------------------------------------------------------------------+
string GetTrendDescription(TrendState trendState)
{
   switch(trendState)
   {
      case NO_TREND:
         return "NO_TREND";
      case UP_TREND:
         return "UP_TREND";
      case DOWN_TREND:
         return "DOWN_TREND";
      case UP_TREND_RETRACEMENT:
         return "UP_TREND_RETRACEMENT";
      case DOWN_TREND_RETRACEMENT:
         return "DOWN_TREND_RETRACEMENT";
      default:
         return "TREND_ERROR_UNKNOW";
   }
}
//+------------------------------------------------------------------+
//| Detect state: retracement, continuation, reversal, etc.          |
//+------------------------------------------------------------------+
TrendState DetectTrendState(int i, TrendState trendState, TrendState lastBarDirection)
{
   TrendState res = trendState;

   printf("DetectTrendState, trendState=%s, lastBarDirection=%s", GetTrendDescription(trendState), GetTrendDescription(lastBarDirection));
   
   PrevPeaks peaks = GetPrevLowHighPeaks(i,Bars);
   printf("DetectTrendState, peakState1=%s, peakState2=%s, peakClose1=%f, peakClose2=%f", GetPeakDescription(peaks.peakState1), GetPeakDescription(peaks.peakState2), peaks.peakClose1, peaks.peakClose2);

   double prevLowClose = -1;
   double prevHighClose = -1;

   if(peaks.peakState1 != LOCAL_HIGH_PEAK || peaks.peakState1 == HIGHER_HIGH_PEAK)
      prevHighClose = peaks.peakClose1;
   else if(peaks.peakState1 != LOCAL_LOW_PEAK || peaks.peakState1 == LOWER_LOW_PEAK)
      prevLowClose = peaks.peakClose1;
   
   if(peaks.peakState2 != LOCAL_HIGH_PEAK || peaks.peakState2 == HIGHER_HIGH_PEAK)
      prevHighClose = peaks.peakClose2;
   else if(peaks.peakState2 != LOCAL_LOW_PEAK || peaks.peakState2 == LOWER_LOW_PEAK)
      prevLowClose = peaks.peakClose2;

   //if(verbose) Print("DetectTrendState, close0=", close0, ", prevLowClose=", prevLowClose, ", prevHighClose=", prevHighClose);
      
   if(trendState == NO_TREND)
   {
      if(lastBarDirection == UP_TREND)
      {
         res = UP_TREND;
         if(verbose) Print("DetectTrendState NO_TREND -> UP_TREND");
      }
      else if(lastBarDirection == DOWN_TREND)
      {
         res = DOWN_TREND;
         if(verbose) Print("DetectTrendState NO_TREND -> DOWN_TREND");
      }     
   }
   else if(trendState == UP_TREND && lastBarDirection == DOWN_TREND)
   {
      res = UP_TREND_RETRACEMENT;
      if(verbose) Print("DetectTrendState UP_TREND -> UP_TREND_RETRACEMENT");
   }
   else if(trendState == UP_TREND_RETRACEMENT)
   {
      if(lastBarDirection == UP_TREND)
      {
         res = UP_TREND;
         if(verbose) Print("DetectTrendState UP_TREND_RETRACEMENT -> UP_TREND");
      }
      else if(prevLowClose == -1 || Close[i+1]  < prevLowClose) 
      {
         res = DOWN_TREND;
         if(verbose) Print("DetectTrendState UP_TREND_RETRACEMENT -> DOWN_TREND");
      }
   }
   else if(trendState == DOWN_TREND && lastBarDirection == UP_TREND)
   {
      res = DOWN_TREND_RETRACEMENT;
      if(verbose) Print("DetectTrendState DOWN_TREND -> DOWN_TREND_RETRACEMENT");
   }
   else if(trendState == DOWN_TREND_RETRACEMENT)
   {
       if(lastBarDirection == DOWN_TREND)
       {
         res = DOWN_TREND;
         if(verbose) Print("DetectTrendState DOWN_TREND_RETRACEMENT -> DOWN_TREND");
       }
       else if (prevHighClose == -1 || Close[i+1] > prevHighClose) 
       {
         res = UP_TREND;
         if(verbose) Print("DetectTrendState DOWN_TREND_RETRACEMENT -> UP_TREND");
       }
   }
   
   return res;
}

//+------------------------------------------------------------------+
//| Detect peaks based on price action logic                         |
//+------------------------------------------------------------------+
PeakState DetectPeakState(int i, int trendState, int newTrend)
{
   //printf("DetectPeakState %s -> %s",GetTrendDescription((TrendState) trendState), GetTrendDescription((TrendState)  newTrend));

   if(trendState == newTrend)
       return NO_PEAK; // No change in trend, keep previous peak state

   PrevPeaks peaks = GetPrevLowHighPeaks(i,Bars);

   PeakState peak_state = NO_PEAK;

   // Up-trend peak logic
   if((trendState == UP_TREND || trendState == DOWN_TREND_RETRACEMENT) && (newTrend == DOWN_TREND || newTrend == UP_TREND_RETRACEMENT))
   {
      //if prev peak is high
      if(peaks.peakState2 == LOCAL_HIGH_PEAK && Close[i+1] > peaks.peakClose2)
      {
         peak_state = HIGHER_HIGH_PEAK;
         if(verbose) Print("DetectPeakState HH");
      }
      else if(peaks.peakState2 == HIGHER_HIGH_PEAK) 
      {
         if(Close[i+1] > peaks.peakClose2)
         {
            peak_state = HIGHER_HIGH_PEAK;
            //PeakBuffer[peaks.peakInd2] = LOCAL_HIGH_PEAK; // update last peak to local peak
            if(verbose) Print("DetectPeakState update HH");
         }
         else
         {
            peak_state = LOCAL_HIGH_PEAK; // update last peak to local peak
            if(verbose) Print("DetectPeakState update H");
         }
      }
      else
      {
         peak_state = LOCAL_HIGH_PEAK;
         if(verbose) Print("DetectPeakState H");
      }  
   }
   else if((trendState == DOWN_TREND || trendState == UP_TREND_RETRACEMENT) && (newTrend == UP_TREND || newTrend == DOWN_TREND_RETRACEMENT))
   {
      //if prev peak is high
      if(peaks.peakState2 == LOCAL_LOW_PEAK && Close[i+1] < peaks.peakClose2)
      {
         peak_state = LOWER_LOW_PEAK;
         if(verbose) Print("DetectPeakState LL");
      }
      else if(peaks.peakState2 == LOWER_LOW_PEAK)
      {
         if(Close[i+1] < peaks.peakClose2)
         {
            peak_state = LOWER_LOW_PEAK;
            //PeakBuffer[peaks.peakInd2] = LOCAL_LOW_PEAK;
            if(verbose) Print("DetectPeakState update LL");
         }
         else
         {
            peak_state = LOCAL_LOW_PEAK; // update last peak to local peak
            if(verbose) Print("DetectPeakState update L");
         }
      }
      else 
      {
         peak_state = LOCAL_LOW_PEAK;
         if(verbose) Print("DetectPeakState L");
      }
   }
   
   return peak_state;
}

//+------------------------------------------------------------------+
//| Visualize peak: draw text at close price (overlay on chart)      |
//+------------------------------------------------------------------+
void VisualizePeakOverlay(int i, int peak_state)
{
   static int peaksCountr = 0;
   string txt = "";
   color col = clrBlack;
   double y_offset = 10 * Point; // Small offset above/below close
   double y = 0;

   switch(peak_state) {
      case LOCAL_HIGH_PEAK:   txt = "\x48";  col = clrBlue;  y = High[i] + 2*y_offset; break;   // "H"
      case LOCAL_LOW_PEAK:    txt = "\x4C";  col = clrRed;   y = Low[i] - y_offset; break;  // "L"
      case HIGHER_HIGH_PEAK:  txt = "HH";    col = clrBlue;  y = High[i] + 2*y_offset; break;
      case LOWER_LOW_PEAK:    txt = "LL";    col = clrRed;   y = Low[i] - y_offset; break;
      default:  return; //              ObjectDelete("peak_" + IntegerToString(i)); return;
   }
   string name = "peak_" + IntegerToString(peaksCountr++) + "_time_" + TimeToString(Time[i], TIME_MINUTES);
   Print("VisualizePeakOverlay: i=", i, " name=", name, ", y=", y);

   ObjectDelete(name);
   ObjectCreate(name, OBJ_TEXT, 0, Time[i], y);
   ObjectSetText(name, txt, 12, "Arial", col);
}

//+------------------------------------------------------------------+
//| Draw lines between consecutive confirmed peaks                   |
//+------------------------------------------------------------------+
void DrawPeakLines(int i)
{
      static int LinesCount = 0;
      PrevPeaks peaks = GetPrevLowHighPeaks(i,Bars);
      if(peaks.peakInd1 == -1 || peaks.peakInd2 == -1)
         return; // No peaks found

      string objName = "peaksline_#" + IntegerToString(LinesCount++) + "_from_" + IntegerToString(peaks.peakInd2) + "_to" + IntegerToString(peaks.peakInd1);
      color lineColor = clrRed;
      
      ObjectDelete(objName);
      ObjectCreate(objName, OBJ_TREND, 0, Time[peaks.peakInd1], Close[peaks.peakInd1], Time[peaks.peakInd2], Close[peaks.peakInd2]);
      ObjectSet(objName, OBJPROP_COLOR, lineColor);
      ObjectSet(objName, OBJPROP_WIDTH, 2);
      ObjectSet(objName, OBJPROP_RAY, false);

      //Print("DrawPeakLines: i=", i, ", ObjName=", objName);
}

//+------------------------------------------------------------------+
//| Clean up old peak lines                                          |
//+------------------------------------------------------------------+
/*void CleanPeakLines()
{
   for(int p=1; p<PeakCount+100; p++)
   {
      string objName = "peakline_" + IntegerToString(p-1) + "_" + IntegerToString(p);
      ObjectDelete(objName);
   }
}
*/

//+------------------------------------------------------------------+
//| Clean up old peak labels                                         |
//+------------------------------------------------------------------+
void CleanPeakLabels()
{
   for(int i=0; i<Bars; i++)
   {
      string name = "peak_" + IntegerToString(i);
      ObjectDelete(name);
   }
}

//+------------------------------------------------------------------+