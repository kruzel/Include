//+------------------------------------------------------------------+
//|                                                       ZigZag.mq4 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2000-2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict

// #property indicator_chart_window
// #property indicator_buffers 1
// #property indicator_color1  Red

#include <Falcon_B/10_isNewBar.mqh>

struct PeakData
{
   datetime time;
   double price;
   int direction; // 1 for high, -1 for low
};

//---- Line Color Legend:
//---- BLUE: All confirmed peaks for current day
//---- RED: Highest peak from previous day  
//---- GREEN: Lowest peak from previous day
//---- indicator parameters
input int InpDepth=12;     // Depth
input int InpDeviation=5;  // Deviation
input int InpBackstep=3;   // Backstep

//---- buffers
int ZigZagBufferSize = 1000;
double ExtZigzagBuffer[1000];
double ExtHighBuffer[1000];
double ExtLowBuffer[1000];
PeakData ConfirmedZigZagPeaks[1000]; 
//--- globals
int daysToDraw = 1; // Number of days to draw lines for confirmed peaks
int    ExtLevel=3; // recounting's depth of extremums
string LinePrefix = "ZigZag_Line_"; // Prefix for horizontal line objects
int    PeakCount = 0; // Counter for confirmed peaks
double LastProcessedHigh = 0; // Last high that was processed
double LastProcessedLow = 0;  // Last low that was processed
int limit;
bool ZZverbose = true; // Verbose mode for debugging

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int ZZInit()
  {
   if(InpBackstep>=InpDepth)
     {
      Print("Backstep cannot be greater or equal to Depth");
      return(INIT_FAILED);
     }
//--- 2 additional buffers
  //  IndicatorBuffers(3);
//---- drawing settings
  //  SetIndexStyle(0,DRAW_SECTION);
//---- indicator buffers
  //  SetIndexBuffer(0,ExtZigzagBuffer);
  //  SetIndexBuffer(1,ExtHighBuffer);
  //  SetIndexBuffer(2,ExtLowBuffer);
  //  SetIndexEmptyValue(0,0.0);
//---- indicator short name
  //  IndicatorShortName("ZigZag("+string(InpDepth)+","+string(InpDeviation)+","+string(InpBackstep)+")");
//---- Clean up any existing lines from previous runs
  //  RemoveAllZigZagLines();

  //  limit=InitializeAll();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ZZProcessBar()
  {
   // Process the current bar and update ZigZag state
   int    i,counterZ,whatlookfor=0;
   int    back,pos,lasthighpos=0,lastlowpos=0;
   double extremum;
   double curlow=0.0,curhigh=0.0,lasthigh=0.0,lastlow=0.0;
      
    if(ZigZagBufferSize < InpDepth || InpBackstep >= InpDepth)
      return(0);

    //--- find first extremum in the depth ExtLevel or 100 last bars
    i=counterZ=0;
    while(counterZ<ExtLevel && i<100)
      {
        if(ExtZigzagBuffer[i]!=0.0)
          counterZ++;
        i++;
      }

    datetime targetDayMidnight = TimeCurrent() - TimeCurrent() % 86400 - daysToDraw*86400;
    datetime nowTime = TimeCurrent();
    int barCount = Bars(NULL, PERIOD_CURRENT, targetDayMidnight, nowTime);
    limit = MathMin(ZigZagBufferSize - InpDepth, barCount);

    if(ZZverbose) Print("ZZProcessBar: Processing new bar at time ", TimeToString(Time[0], TIME_DATE | TIME_MINUTES), ", limit=", limit, ", barCount=", barCount);

    //--- no extremum found - recounting all from begin
    if(counterZ==0)
        InitializeAll();
    else
      {
        //--- what kind of extremum?
        if(ExtLowBuffer[i]!=0.0) 
          {
          //--- low extremum
          curlow=ExtLowBuffer[i];
          //--- will look for the next high extremum
          whatlookfor=1;
          }
        else
          {
          //--- high extremum
          curhigh=ExtHighBuffer[i];
          //--- will look for the next low extremum
          whatlookfor=-1;
          }
        //--- clear the rest data
        for(i=limit-1; i>=0; i--)  
          {
          ExtZigzagBuffer[i]=0.0;  
          ExtLowBuffer[i]=0.0;
          ExtHighBuffer[i]=0.0;
          }
      }
//--- main loop      
   for(i=limit; i>=0; i--)
     {
      //--- find lowest low in depth of bars
      extremum=Low[iLowest(NULL,0,MODE_LOW,InpDepth,i)];
      //--- this lowest has been found previously
      if(extremum==lastlow)
         extremum=0.0;
      else 
        { 
         //--- new last low
         lastlow=extremum; 
         //--- discard extremum if current low is too high
         if(Low[i]-extremum>InpDeviation*Point)
            extremum=0.0;
         else
           {
            //--- clear previous extremums in backstep bars
            for(back=1; back<=InpBackstep; back++)
              {
               pos=i+back;
               if(ExtLowBuffer[pos]!=0 && ExtLowBuffer[pos]>extremum)
                  ExtLowBuffer[pos]=0.0; 
              }
           }
        } 
      //--- found extremum is current low
      if(Low[i]==extremum)
         ExtLowBuffer[i]=extremum;
      else
         ExtLowBuffer[i]=0.0;
      //--- find highest high in depth of bars
      extremum=High[iHighest(NULL,0,MODE_HIGH,InpDepth,i)];
      //--- this highest has been found previously
      if(extremum==lasthigh)
         extremum=0.0;
      else 
        {
         //--- new last high
         lasthigh=extremum;
         //--- discard extremum if current high is too low
         if(extremum-High[i]>InpDeviation*Point)
            extremum=0.0;
         else
           {
            //--- clear previous extremums in backstep bars
            for(back=1; back<=InpBackstep; back++)
              {
               pos=i+back;
               if(ExtHighBuffer[pos]!=0 && ExtHighBuffer[pos]<extremum)
                  ExtHighBuffer[pos]=0.0; 
              } 
           }
        }
      //--- found extremum is current high
      if(High[i]==extremum)
         ExtHighBuffer[i]=extremum;
      else
         ExtHighBuffer[i]=0.0;
     }
//--- final cutting 
   if(whatlookfor==0)
     {
      lastlow=0.0;
      lasthigh=0.0;  
     }
   else
     {
      lastlow=curlow;
      lasthigh=curhigh;
     }
   for(i=limit; i>=0; i--)
     {
      switch(whatlookfor)
        {
         case 0: // look for peak or lawn 
            if(lastlow==0.0 && lasthigh==0.0)
              {
               if(ExtHighBuffer[i]!=0.0)
                 {
                  lasthigh=High[i];
                  lasthighpos=i;
                  whatlookfor=-1;
                  ExtZigzagBuffer[i]=lasthigh;
                 }
               if(ExtLowBuffer[i]!=0.0)
                 {
                  lastlow=Low[i];
                  lastlowpos=i;
                  whatlookfor=1;
                  ExtZigzagBuffer[i]=lastlow;
                 }
              }
             break;  
         case 1: // look for peak
            if(ExtLowBuffer[i]!=0.0 && ExtLowBuffer[i]<lastlow && ExtHighBuffer[i]==0.0)
              {
               ExtZigzagBuffer[lastlowpos]=0.0;
               lastlowpos=i;
               lastlow=ExtLowBuffer[i];
               ExtZigzagBuffer[i]=lastlow;
              }
            if(ExtHighBuffer[i]!=0.0 && ExtLowBuffer[i]==0.0)
              {
               lasthigh=ExtHighBuffer[i];
               lasthighpos=i;
               ExtZigzagBuffer[i]=lasthigh;
               whatlookfor=-1;
              }   
            break;               
         case -1: // look for lawn
            if(ExtHighBuffer[i]!=0.0 && ExtHighBuffer[i]>lasthigh && ExtLowBuffer[i]==0.0)
              {
               ExtZigzagBuffer[lasthighpos]=0.0;
               lasthighpos=i;
               lasthigh=ExtHighBuffer[i];
               ExtZigzagBuffer[i]=lasthigh;
              }
            if(ExtLowBuffer[i]!=0.0 && ExtHighBuffer[i]==0.0)
              {
               lastlow=ExtLowBuffer[i];
               lastlowpos=i;
               ExtZigzagBuffer[i]=lastlow;
               whatlookfor=1;
              }   
            break;               
        }
     }
//--- Draw horizontal lines at all extremums
   DetectResistanceLines();
//--- done
   return(limit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int InitializeAll()
  {
   ArrayInitialize(ExtZigzagBuffer,0.0);
   ArrayInitialize(ExtHighBuffer,0.0);
   ArrayInitialize(ExtLowBuffer,0.0);
   ZeroMemory(ConfirmedZigZagPeaks);
   PeakCount = 0;
   LastProcessedHigh = 0;
   LastProcessedLow = 0;
  //---- initialization done
  //--- first counting position
   datetime targetDayMidnight = TimeCurrent() - TimeCurrent() % 86400 - daysToDraw*86400;
   datetime nowTime = TimeCurrent();
   int barCount = Bars(NULL, PERIOD_CURRENT, targetDayMidnight, nowTime);
   limit = MathMin(ZigZagBufferSize - InpDepth, barCount);
   Print("InitializeAll: targetDayMidnight=", TimeToString(targetDayMidnight, TIME_DATE | TIME_MINUTES), ", nowTime=", TimeToString(nowTime, TIME_DATE | TIME_MINUTES), " Bars count=", barCount, " limit=", limit);
   return(limit);
  }
//+------------------------------------------------------------------+
//| Create Horizontal Line Function                                  |
//+------------------------------------------------------------------+
void CreateHorizontalLine(double price, datetime time_start, color line_color, string line_name, datetime time_end)
  {
    Print("CreateHorizontalLine: price=", price, ", time_start=", TimeToString(time_start, TIME_DATE | TIME_MINUTES), 
          ", line_name=", line_name, ", time_end=", TimeToString(time_end, TIME_DATE | TIME_MINUTES));
// Create trend line starting from peak and extending to the specified end time
   if(ObjectFind(line_name) == -1) // Check if line doesn't exist
     {
      // Create trend line from peak time to end time at same price level
      ObjectCreate(line_name, OBJ_TREND, 0, time_start, price, time_end, price);
      ObjectSet(line_name, OBJPROP_COLOR, line_color);
      ObjectSet(line_name, OBJPROP_WIDTH, 1);
      ObjectSet(line_name, OBJPROP_STYLE, STYLE_SOLID);
      // ObjectSet(line_name, OBJPROP_BACK, true); // Draw in background
      ObjectSet(line_name, OBJPROP_RAY, false); // Don't extend indefinitely
      // ObjectSet(line_name, OBJPROP_SELECTABLE, false);
     }
  //  else
  //    {
  //     // Update existing line coordinates
  //     ObjectSet(line_name, OBJPROP_TIME1, time_start);
  //     ObjectSet(line_name, OBJPROP_PRICE1, price);
  //     ObjectSet(line_name, OBJPROP_TIME2, time_end);
  //     ObjectSet(line_name, OBJPROP_PRICE2, price);
  //    }
  }
//+------------------------------------------------------------------+
//| Draw Support Resistance Lines Function                           |
//+------------------------------------------------------------------+
void DetectResistanceLines()
  {
// Draw horizontal lines for:
// 1. All confirmed peaks for current day (blue)
// 2. Highest peak for previous day (red)
// 3. Lowest peak for previous day (green)
   
   // Clear the confirmed peaks array to rebuild it
   ZeroMemory(ConfirmedZigZagPeaks);
   PeakCount = 0;
   
   // Get current day and previous day boundaries
   datetime currentDayStart = iTime(NULL, PERIOD_D1, 0);
   datetime previousDayStart = iTime(NULL, PERIOD_D1, 1);
   datetime previousDayEnd = currentDayStart;
   datetime currentDayEnd = currentDayStart + 86400; // Current day end (next day start)
   
   // Variables to track previous day extremes
   double previousDayHighest = 0.0;
   double previousDayLowest = 999999.0;
   int previousDayHighestBar = -1;
   int previousDayLowestBar = -1;
   
   // First pass: Find previous day's highest and lowest ZigZag peaks
   for(int i = limit - 1; i >= 1; i--)
     {
      if(ExtZigzagBuffer[i] != 0.0)
        {
         datetime barTime = Time[i];
         
         // Check if this bar belongs to the previous day
         if(barTime >= previousDayStart && barTime < previousDayEnd)
           {
            double extremum_price = ExtZigzagBuffer[i];
            
            // Check if this is a high point and higher than current highest
            if(ExtHighBuffer[i] != 0.0 && extremum_price > previousDayHighest)
              {
               previousDayHighest = extremum_price;
               previousDayHighestBar = i;
              }
            
            // Check if this is a low point and lower than current lowest
            if(ExtLowBuffer[i] != 0.0 && extremum_price < previousDayLowest)
              {
               previousDayLowest = extremum_price;
               previousDayLowestBar = i;
              }
           }
        }
     }
   
   // Second pass: Find confirmed peaks for all days and create lines
   for(int i = limit - 1; i >= 10; i--)
     {
      if(ExtZigzagBuffer[i] != 0.0)
        {
         datetime barTime = Time[i];
         double extremum_price = ExtZigzagBuffer[i];
         bool createLine = false;
         color lineColor = clrBlue;
         string lineType = "";
         datetime lineStartTime = currentDayStart;
         
         // Check if this is a current day peak
         if(barTime >= currentDayStart)
           {
            // Apply confirmation logic for current day peaks
            bool isConfirmedPeak = false;
            int nextZigZagBar = -1;
            int barsGap = 0;
            
            // Look for the next ZigZag point to confirm direction change
            for(int j = i - 1; j >= 1; j--)
              {
               if(ExtZigzagBuffer[j] != 0.0)
                 {
                  nextZigZagBar = j;
                  barsGap = i - j;
                  break;
                 }
              }
            
            // Confirm this is a turning point
            if(nextZigZagBar != -1 && barsGap >= 3) // Reduced gap for current day
              {
               bool isCurrentHigh = (ExtHighBuffer[i] != 0.0 && ExtHighBuffer[i] == extremum_price);
               bool isCurrentLow = (ExtLowBuffer[i] != 0.0 && ExtLowBuffer[i] == extremum_price);
               bool isNextHigh = (ExtHighBuffer[nextZigZagBar] != 0.0);
               bool isNextLow = (ExtLowBuffer[nextZigZagBar] != 0.0);
               
               if((isCurrentHigh && isNextLow) || (isCurrentLow && isNextHigh))
                 {
                  isConfirmedPeak = true;
                 }
              }
            else if(nextZigZagBar == -1 && i < Bars - 5)
              {
               isConfirmedPeak = true; // Most recent point, less strict
              }
            
            if(isConfirmedPeak)
              {
               createLine = true;
               lineColor = clrBlue;
               if(ExtHighBuffer[i] != 0.0)
                 lineType = "Current_Day_High";
               else
                 lineType = "Current_Day_Low";
              }
           }
         // Check if this is the previous day's highest peak
         else if(i == previousDayHighestBar && previousDayHighest > 0.0)
           {
            createLine = true;
            lineColor = clrRed;
            lineType = "Previous_Day_Highest";
           }
         // Check if this is the previous day's lowest peak
         else if(i == previousDayLowestBar && previousDayLowest < 999999.0)
           {
            createLine = true;
            lineColor = clrGreen;
            lineType = "Previous_Day_Lowest";
           }

         // Create the line if criteria met
         if(createLine && PeakCount < 1000)
           {
            // Check if this price level is already in our confirmed list
            bool alreadyExists = false;
            for(int k = 0; k < PeakCount; k++)
              {
               if(MathAbs(ConfirmedZigZagPeaks[k].price - extremum_price) < Point * 2)
                 {
                  alreadyExists = true;
                  break;
                 }
              }
            
            if(!alreadyExists)
              {
               ConfirmedZigZagPeaks[PeakCount].price = extremum_price;
               ConfirmedZigZagPeaks[PeakCount].time = Time[i];
               ConfirmedZigZagPeaks[PeakCount].direction = (ExtHighBuffer[i] != 0.0) ? 1 : -1;
               PeakCount++;
               
               // Determine the appropriate end time for the line
               datetime lineEndTime;
               datetime lineStartTime = Time[i];
               if(barTime >= currentDayStart)
                 {
                  // Current day peak - line ends at current day end
                  lineEndTime = currentDayEnd;
                 }
               else if(StringFind(lineType, "Previous_Day") >= 0)
                 {
                  // Previous day peak (red/green lines) - extend to current day end
                  lineEndTime = currentDayEnd;
                  lineStartTime = currentDayStart;
                 }

                 string line_name = LinePrefix + lineType + "_" + DoubleToString(extremum_price, Digits) + "_" + TimeToString(lineEndTime, TIME_DATE | TIME_MINUTES);
               
               
               CreateHorizontalLine(extremum_price, Time[i], lineColor, line_name, lineEndTime);
              }
           }
        }
     }
     
   // Clean up any obsolete lines that are no longer confirmed
  //  CleanupObsoletePeakLines();
  }
//+------------------------------------------------------------------+
//| Clean Up Obsolete Peak Lines Function                            |
//+------------------------------------------------------------------+
void CleanupObsoletePeakLines()
  {
// Remove lines for peaks that are no longer confirmed ZigZag extremums
// But preserve previous day's red and green lines
   
   int total_objects = ObjectsTotal();
   
   for(int i = total_objects - 1; i >= 0; i--)
     {
      string obj_name = ObjectName(i);
      
      // Check if this is one of our ZigZag lines
      if(StringFind(obj_name, LinePrefix) == 0)
        {
        //  Skip deletion of previous day lines (red and green)
         if(StringFind(obj_name, "Previous_Day_Highest") >= 0 || 
            StringFind(obj_name, "Previous_Day_Lowest") >= 0)
           {
            continue; // Don't delete previous day lines
           }
         
         // Extract price from line name to check if it's still a confirmed peak
         double line_price = ObjectGet(obj_name, OBJPROP_PRICE1);
         bool stillConfirmed = false;
         
         // Check if this price is still in our confirmed peaks array
         for(int j = 0; j < PeakCount; j++)
           {
            if(MathAbs(ConfirmedZigZagPeaks[j].price - line_price) < Point)
              {
               stillConfirmed = true;
               break;
              }
           }
         
         // If not confirmed anymore, remove the line
        //  if(!stillConfirmed)
        //    {
        //     // if(PAverbose) Print("CleanupObsoletePeakLines: Deleting obsolete line ", obj_name);
        //     ObjectDelete(obj_name);
        //    }
        }
     }
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void ZZDeinit(const int reason)
  {
// Remove all horizontal lines created by this indicator
  //  RemoveAllZigZagLines();
  }
//+------------------------------------------------------------------+
//| Remove All ZigZag Lines Function                                 |
//+------------------------------------------------------------------+
void RemoveAllZigZagLines()
  {
// Remove all horizontal lines created by this indicator
// But preserve previous day's red and green lines
   
   int total_objects = ObjectsTotal();
   
   for(int i = total_objects - 1; i >= 0; i--)
     {
      string obj_name = ObjectName(i);
      
      // Check if object name starts with our prefix
      if(StringFind(obj_name, LinePrefix) == 0)
        {
         // Skip deletion of previous day lines (red and green)
        //  if(StringFind(obj_name, "Previous_Day_Highest") >= 0 || 
        //     StringFind(obj_name, "Previous_Day_Lowest") >= 0)
        //    {
        //     continue; // Don't delete previous day lines
        //    }
         
         ObjectDelete(obj_name);
        }
     }
  }
//+------------------------------------------------------------------+
//| Check Support Function                                            |
//+------------------------------------------------------------------+
enum SRCheckResult
{
  SR_NOT_NEAR,
  BELOW_HIGHER_SR,
  ABOVE_HIGHER_SR,
  ABOVE_LOWER_SR,
  BELOW_LOWER_SR
};

SRCheckResult CheckSupportResistance(double price, double threshold)
{
  for(int j = 0; j < PeakCount; j++)
  {
    if((ConfirmedZigZagPeaks[j].price - price) > 0 && (ConfirmedZigZagPeaks[j].price - price) < threshold)
    {
      return BELOW_HIGHER_SR; // Found a confirmed peak near the price
    }
    else if((price - ConfirmedZigZagPeaks[j].price) > 0 && (price - ConfirmedZigZagPeaks[j].price) < threshold)
    {
      return ABOVE_LOWER_SR; // Found a confirmed peak near the price
    }
  }

  if((LastProcessedHigh - price) > 0 && (LastProcessedHigh - price) < threshold)
  {
    return BELOW_HIGHER_SR; // Found a confirmed peak near the price
  }
  
  if((LastProcessedLow - price) > 0 && (LastProcessedLow - price) < threshold)
  {
    return ABOVE_LOWER_SR; // Found a confirmed peak near the price
  }

  return SR_NOT_NEAR;
}