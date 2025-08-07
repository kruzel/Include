//+------------------------------------------------------------------+
//|                                                PriceAction.mq4   |
//|                Modular Price Action Events Indicator             |
//+------------------------------------------------------------------+


#include <Falcon_B_Include/enums.mqh>

//+------------------------------------------------------------------+
//| Setup parameters
//+------------------------------------------------------------------+
extern string  HeaderPA="----------Trend States Detection Settings-----------";
extern double TrendMargin = 0; // Trend Detection Margin
extern bool PAverbose = false; // Verbose output for debugging
extern bool UseVisualizePeakOverlay = true; // Visualize peaks on chart
extern bool UseDrawPeakLines = false; // Draw lines for peaks

enum PeakState {
   NO_PEAK = 0,
   LOWER_HIGH_PEAK = 1,
   HIGHER_LOW_PEAK = 2,
   HIGHER_HIGH_PEAK = 3,
   LOWER_LOW_PEAK = 4
};

struct PrevPeaks 
{
   int peakTime1;
   double peakClose1; //last
   PeakState peakState1;
   int peakTime2;
   double peakClose2; // before last
   PeakState peakState2;
};

struct PaResults
{
   int errorCode; // 0 - no error, other values indicate errors
   TrendState prevTrendState;
   TrendState trendState;
   PeakState prevBarPeakState;
};

//--- internal state variables
struct PriceActionState
{
   TrendState trendState;
   datetime peakTime1;
   double  peakClose1; //last
   PeakState peakState1;
   datetime peakTime2;
   double  peakClose2; // before last
   PeakState peakState2;
   
   datetime peakTimeHighest;
   double  peakCloseHighest; //last
   PeakState peakStateHighest;
   datetime peakTimeLowest;
   double  peakCloseLowest; // before last
   PeakState peakStateLowest;
};
static PriceActionState priceActionState;

int PaInit()
{
   PaResults results;
   results.errorCode = 0; // No error
   results.prevTrendState = NO_TREND;
   results.trendState = NO_TREND;
   results.prevBarPeakState = NO_PEAK;

   if (Bars < 3) return (0);

   priceActionState.trendState = NO_TREND;
   priceActionState.peakTime1 = Time[Bars-1];
   priceActionState.peakClose1 = -1; //last
   priceActionState.peakState1 = NO_PEAK;
   priceActionState.peakTime2 = Time[Bars-1];
   priceActionState.peakClose2 = -1; // before last
   priceActionState.peakState2 = NO_PEAK;

   priceActionState.peakTimeHighest = Time[Bars-1];
   priceActionState.peakCloseHighest = -1; 
   priceActionState.peakStateHighest = NO_PEAK;
   priceActionState.peakTimeLowest = Time[Bars-1];
   priceActionState.peakCloseLowest = -1; 
   priceActionState.peakStateLowest = NO_PEAK;
   
   int numBarsToProcess = MathMin(Bars - 2, 100); // Process last 100 bars or less if not enough data

   for(int i=numBarsToProcess; i>=1; i--)
   {
      //if (i < Bars - 1) // Only process if there's a next bar
      results = ProcessBar(i);
      if (results.errorCode != 0) 
      {
         return results.errorCode; // Return error code if any
      }
   }

   return(0);
}

int PaDeinit()
{
   // Clean up all objects before redrawing
   CleanPeakLabels();
   CleanPeakLines();
   
   return 0;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
PaResults PaProcessBars(int i)
{
   PaResults results;
   results.errorCode = 0; // Error code 1 indicates processing error
   results.trendState = NO_TREND;
   results.prevBarPeakState = NO_PEAK;

   static datetime lastBarTime = 0;
   if(Time[0] != lastBarTime) {
      lastBarTime = Time[0];
      results = ProcessBar(i); // process the just-completed bar
   }

   return results;
}

//+------------------------------------------------------------------+
//| Process logic for a single bar                                   |
//+------------------------------------------------------------------+
PaResults ProcessBar(int i)
{
   PaResults results;
   results.errorCode = 0; // Error code 1 indicates processing error
   results.prevTrendState = NO_TREND;
   results.trendState = NO_TREND;
   results.prevBarPeakState = NO_PEAK;

   if(PAverbose) Print("ProcessBar start i=", i, ", Time=", TimeToString(Time[i], TIME_DATE | TIME_MINUTES), "--------------------");
   if(PAverbose) printf("ProcessBar 1, peakTime1=%s, peakTime2=%s", TimeToString(priceActionState.peakTime1), TimeToString(priceActionState.peakTime2));

   PeakState peak_state = NO_PEAK;

   TrendState lastBarDirection = DetectBarDirection(Close[i+1], Close[i]);

   TrendState newTrend = DetectTrendState(i, priceActionState.trendState, lastBarDirection);

   PeakState peakState = DetectPeakState(i, priceActionState.trendState, newTrend);

   if(peakState != NO_PEAK)
   {
      if(PAverbose) printf("ProcessBar 2, peakTime1=%d, peakTime2=%d", priceActionState.peakTime1, priceActionState.peakTime2);
      // update internal peaks state
      priceActionState.peakTime2 = priceActionState.peakTime1;
      priceActionState.peakClose2 = priceActionState.peakClose1;
      priceActionState.peakState2 = priceActionState.peakState1;

      priceActionState.peakTime1 = Time[i+1];
      priceActionState.peakClose1 = Close[i+1]; //last
      priceActionState.peakState1 = peakState;

      if(peakState == HIGHER_HIGH_PEAK)
      {
         priceActionState.peakTimeHighest = Time[i+1];
         priceActionState.peakCloseHighest = Close[i+1]; 
         priceActionState.peakStateHighest = HIGHER_HIGH_PEAK;
      }
      else if(peakState == LOWER_LOW_PEAK)
      {
         priceActionState.peakTimeLowest = Time[i+1];
         priceActionState.peakCloseLowest = Close[i+1]; 
         priceActionState.peakStateLowest = LOWER_LOW_PEAK;
      }

      if(PAverbose) printf("ProcessBar 3, peakTime1=%s, peakTime2=%s", TimeToString(priceActionState.peakTime1), TimeToString(priceActionState.peakTime2));

      if(UseVisualizePeakOverlay) VisualizePeakOverlay(i+1, peakState);
      if(UseDrawPeakLines) DrawPeakLines();
   }

   // results
   results.prevTrendState = priceActionState.trendState;
   results.trendState = newTrend;
   results.prevBarPeakState = peakState;
   
   // update internal state
   priceActionState.trendState = newTrend;
   
   if(PAverbose) Print("ProcessBar end i=", i, ", newTrend=", GetTrendDescription((TrendState)newTrend), 
                     ", peakState=", GetPeakDescription((PeakState)peakState), "--------------------");
   // if(PAverbose) Print("ProcessBar end i=", i, ", peakState1=", GetPeakDescription(priceActionState.peakState1), 
   //                   ", peakState2=", GetPeakDescription((priceActionState.peakState2)), "--------------------");

   return results;
}

//+------------------------------------------------------------------+
//| return last two peaks                                            |
//+------------------------------------------------------------------+
PriceActionState GetPrevPeaks()
{
   return priceActionState;
}


//+------------------------------------------------------------------+
//| Detect the basic trend between two closes                        |
//+------------------------------------------------------------------+
TrendState DetectBarDirection(double prevClose, double currClose)
{
   if(currClose > prevClose + Point*TrendMargin)
   {
      if(PAverbose) Print("DetectBarDirection UP");
      return UP_TREND;
   }
   else if(currClose < prevClose - Point*TrendMargin)
   {
      if(PAverbose) Print("DetectBarDirection DOWN");
      return DOWN_TREND;
   }
   else
   {
      if(PAverbose) Print("DetectBarDirection NO Direction");
      return NO_TREND;
   }
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
      case LOWER_HIGH_PEAK:
         return "LOWER_HIGH_PEAK";     
      case HIGHER_LOW_PEAK:
         return "HIGHER_LOW_PEAK";
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

   if(PAverbose) printf("DetectTrendState, trendState=%s, lastBarDirection=%s", GetTrendDescription(trendState), GetTrendDescription(lastBarDirection));  
   if(PAverbose) printf("DetectTrendState, peakState1=%s, peakState2=%s", GetPeakDescription(priceActionState.peakState1), GetPeakDescription(priceActionState.peakState2));
   if(PAverbose) printf("DetectTrendState, peakClose1=%f, peakClose2=%f", priceActionState.peakClose1, priceActionState.peakClose2);

   double prevLowClose = -1;
   double prevHighClose = -1;

   if((priceActionState.peakState1 != LOWER_HIGH_PEAK || priceActionState.peakState1 == HIGHER_HIGH_PEAK) &&
      (priceActionState.peakState2 != HIGHER_LOW_PEAK || priceActionState.peakState2 == LOWER_LOW_PEAK))
   {
      prevHighClose = priceActionState.peakClose1;
      prevLowClose = priceActionState.peakClose2;
   }
   else if((priceActionState.peakState1 != HIGHER_LOW_PEAK || priceActionState.peakState1 == LOWER_LOW_PEAK) && 
      (priceActionState.peakState2 != LOWER_HIGH_PEAK || priceActionState.peakState2 == HIGHER_HIGH_PEAK))
   {
      prevLowClose = priceActionState.peakClose1;
      prevHighClose = priceActionState.peakClose2;
   }  
   else
   {
      Print("DetectTrendState failed to find prevous peaks");
   }

   //if(PAverbose) Print("DetectTrendState, close0=", close0, ", prevLowClose=", prevLowClose, ", prevHighClose=", prevHighClose);
      
   if(trendState == NO_TREND)
   {
      if(lastBarDirection == UP_TREND)
      {
         res = UP_TREND;
         if(PAverbose) Print("DetectTrendState NO_TREND -> UP_TREND");
      }
      else if(lastBarDirection == DOWN_TREND)
      {
         res = DOWN_TREND;
         if(PAverbose) Print("DetectTrendState NO_TREND -> DOWN_TREND");
      }     
   }
   else if(trendState == UP_TREND && lastBarDirection == DOWN_TREND)
   {
      res = UP_TREND_RETRACEMENT;
      if(PAverbose) Print("DetectTrendState UP_TREND -> UP_TREND_RETRACEMENT");
   }
   else if(trendState == UP_TREND_RETRACEMENT)
   {
      if(lastBarDirection == UP_TREND)
      {
         res = UP_TREND;
         if(PAverbose) Print("DetectTrendState UP_TREND_RETRACEMENT -> UP_TREND");
      }
      else if(lastBarDirection == DOWN_TREND && (prevLowClose == -1 || Close[i]  < prevLowClose)) 
      {
         res = DOWN_TREND;
         if(PAverbose) Print("DetectTrendState UP_TREND_RETRACEMENT -> DOWN_TREND");
      } else
         res = UP_TREND_RETRACEMENT;
   }
   else if(trendState == DOWN_TREND && lastBarDirection == UP_TREND)
   {
      res = DOWN_TREND_RETRACEMENT;
      if(PAverbose) Print("DetectTrendState DOWN_TREND -> DOWN_TREND_RETRACEMENT");
   }
   else if(trendState == DOWN_TREND_RETRACEMENT)
   {
       if(lastBarDirection == DOWN_TREND)
       {
         res = DOWN_TREND;
         if(PAverbose) Print("DetectTrendState DOWN_TREND_RETRACEMENT -> DOWN_TREND");
       }
       else if (lastBarDirection == UP_TREND && (prevHighClose == -1 || Close[i] > prevHighClose)) 
       {
         res = UP_TREND;
         if(PAverbose) Print("DetectTrendState DOWN_TREND_RETRACEMENT -> UP_TREND");
       }
       else
         res = DOWN_TREND_RETRACEMENT;
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

   PeakState peak_state = NO_PEAK;

   // Up-trend peak logic
   if((trendState == UP_TREND || trendState == DOWN_TREND_RETRACEMENT) && (newTrend == DOWN_TREND || newTrend == UP_TREND_RETRACEMENT))
   {
      //if prev peak is high
      if(priceActionState.peakState2 == LOWER_HIGH_PEAK && Close[i] > priceActionState.peakClose2)
      {
         peak_state = HIGHER_HIGH_PEAK;
         if(PAverbose) Print("DetectPeakState HH");
      }
      else if(priceActionState.peakState2 == HIGHER_HIGH_PEAK) 
      {
         if(Close[i+1] > priceActionState.peakClose2)
         {
            peak_state = HIGHER_HIGH_PEAK;
            if(PAverbose) Print("DetectPeakState update HH");
         }
         else
         {
            peak_state = LOWER_HIGH_PEAK; // update last peak to local peak
            if(PAverbose) Print("DetectPeakState update LH");
         }
      }
      else
      {
         peak_state = LOWER_HIGH_PEAK;
         if(PAverbose) Print("DetectPeakState LH");
      }  
   }
   else if((trendState == DOWN_TREND || trendState == UP_TREND_RETRACEMENT) && (newTrend == UP_TREND || newTrend == DOWN_TREND_RETRACEMENT))
   {
      //if prev peak is high
      if(priceActionState.peakState2 == HIGHER_LOW_PEAK && Close[1] < priceActionState.peakClose2)
      {
         peak_state = LOWER_LOW_PEAK;
         if(PAverbose) Print("DetectPeakState LL");
      }
      else if(priceActionState.peakState2 == LOWER_LOW_PEAK)
      {
         if(Close[i+1] < priceActionState.peakClose2)
         {
            peak_state = LOWER_LOW_PEAK;
            if(PAverbose) Print("DetectPeakState update LL");
         }
         else
         {
            peak_state = HIGHER_LOW_PEAK; // update last peak to local peak
            if(PAverbose) Print("DetectPeakState update HL");
         }
      }
      else 
      {
         peak_state = HIGHER_LOW_PEAK;
         if(PAverbose) Print("DetectPeakState HL");
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
   int Pip;
   if(Digits==5 || Digits==3) Pip=10;else Pip=1;
   double y_offset = Point; // Small offset above/below close
   double y = 0;

   switch(peak_state) {
      case LOWER_HIGH_PEAK:   txt = "LH";  col = clrBlack;  y = High[i] + 40*y_offset; break;   // "H"
      case HIGHER_LOW_PEAK:    txt = "HL";  col = clrBlack;   y = Low[i] - 2*y_offset; break;  // "L"
      case HIGHER_HIGH_PEAK:  txt = "HH";    col = clrBlack;  y = High[i] + 40*y_offset; break;
      case LOWER_LOW_PEAK:    txt = "LL";    col = clrBlack;   y = Low[i] - 2*y_offset; break;
      default:  return; //              ObjectDelete("peak_" + IntegerToString(i)); return;
   }
   string name = "peak_" + IntegerToString(peaksCountr++) + "_time_" + TimeToString(Time[i], TIME_MINUTES) + "_" + GetPeakDescription((PeakState)peak_state);
   if(PAverbose) Print("VisualizePeakOverlay: i=", i, " name=", name, ", y=", y);

   ObjectDelete(name);
   ObjectCreate(name, OBJ_TEXT, 0, Time[i], y);
   ObjectSetText(name, txt, 12, "Arial", col);
}

//+------------------------------------------------------------------+
//| Draw lines between consecutive confirmed peaks                   |
//+------------------------------------------------------------------+
void DrawPeakLines()
{
      static int LinesCount = 0;

      if(priceActionState.peakState1 == NO_PEAK || priceActionState.peakState2 == NO_PEAK)
         return; // No peaks found

      // printf("DrawPeakLines, peakTime1=%s, peakTime2=%s", TimeToString(priceActionState.peakTime1), TimeToString(priceActionState.peakTime2));

      string objName = "peaksline_#" + IntegerToString(LinesCount++) + "_from_" + TimeToString(priceActionState.peakTime2) + "_to_" + TimeToString(priceActionState.peakTime1);
      color lineColor = clrWhite;

      int barIndex1 = iBarShift(NULL, 0, priceActionState.peakTime1);
      int barIndex2 = iBarShift(NULL, 0, priceActionState.peakTime2);

      double price1 = Close[barIndex1];
      double price2 = Close[barIndex2];

      // if(priceActionState.peakState1 == LOWER_HIGH_PEAK || priceActionState.peakState1 == HIGHER_HIGH_PEAK) 
      // {
      //    price1 = High[barIndex1];
      //    price2 = Low[barIndex2];
      // }
      // else if(priceActionState.peakState1 == HIGHER_LOW_PEAK || priceActionState.peakState1 == LOWER_LOW_PEAK)
      // {
      //    price1 = Low[barIndex1];
      //    price2 = High[barIndex2];
      // }
      // else
      // {
      //    Print("DrawPeakLines: Invalid peak state, cannot draw line");
      //    return;
      // }

      ObjectDelete(objName);
      ObjectCreate(objName, OBJ_TREND, 0, priceActionState.peakTime1, price1, priceActionState.peakTime2, price2);
      ObjectSet(objName, OBJPROP_COLOR, lineColor);
      ObjectSet(objName, OBJPROP_WIDTH, 2);
      ObjectSet(objName, OBJPROP_RAY, false);

      if(PAverbose) Print("DrawPeakLines: ObjName=", objName);
}

//+------------------------------------------------------------------+
//| Clean up old peak lines                                          |
//+------------------------------------------------------------------+
void CleanPeakLines()
{
   int total = ObjectsTotal();        // Get total number of objects (main window)
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(i);   // Retrieve the object's name by index
      if(StringFind(name,"peaksline_#")>=0)
         ObjectDelete(name);
   }
}

//+------------------------------------------------------------------+
//| Clean up old peak labels                                         |
//+------------------------------------------------------------------+
void CleanPeakLabels()
{
    int total = ObjectsTotal();        // Get total number of objects (main window)
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(i);   // Retrieve the object's name by index
      if(StringFind(name,"peak_")>=0)
         ObjectDelete(name);
   }
}

//+------------------------------------------------------------------+