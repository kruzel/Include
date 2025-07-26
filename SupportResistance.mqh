//+------------------------------------------------------------------+
//|                                            SupportResistance.mqh |
//|                                                                  |
//|                           Support and Resistance Level Detection |
//+------------------------------------------------------------------+

#property strict

// Enums for trend and SR status
enum SR_TREND_TYPE
{
   SR_UP_TREND = 1,
   SR_DOWN_TREND = -1
};

enum SR_STATUS
{
   NOT_NEAR_SR = 0,
   BELOW_RESISTANCE = 1,
   ABOVE_RESISTANCE = 2,
   ABOVE_SUPPORT = 3,
   BELOW_SUPPORT = 4
};

// Structure to hold support/resistance points
struct SRPoint
{
   double price;
   datetime time;
   bool isSupport;
   
   SRPoint() : price(0), time(0), isSupport(true) {}
   SRPoint(double p, datetime t, bool support) : price(p), time(t), isSupport(support) {}
};

class CSupportResistance
{
private:
   // ZigZag parameters
   int zigzagDepth;
   int zigzagDeviation;
   int zigzagBackstep;
   
   // Margin for SR proximity check
   double margin;
   double P;
   
   // Arrays to store current day SR points
   SRPoint currDaySupportPoints[];
   SRPoint currDayResistancePoints[];
   SRPoint currDaySRpoints[];
   
   // Line objects management
   string linePrefix;
   int lineCounter;
   
   // Previous day extreme values
   double prevDayHighest;
   double prevDayLowest;
   datetime prevDayStart;
   datetime currDayStart;
   
   // Helper methods
   bool IsNewDay(datetime currentTime, datetime previousTime);
   void ClearCurrentDayLines(datetime dayStart);
   void ClearCurrentDayPoints();
   void DrawHorizontalLine(string name, double price, datetime startTime, datetime endTime, color lineColor, int width = 1);
   void FindZigZagPoints(datetime dayStart, datetime dayEnd);
   void FindPreviousDayExtremes(datetime dayStart);
   datetime GetDayStart(datetime time);
   datetime GetDayEnd(datetime time);
   
public:
   // Constructor
   CSupportResistance(double marginPips = 10.0, int depth = 12, int deviation = 5, int backstep = 3);
   
   // Destructor
   ~CSupportResistance();
   
   // Main update method
   void SRUpdate(int i);
   
   // Check proximity to SR levels
   SR_STATUS CheckNearSR(double price, datetime time, SR_TREND_TYPE trend);
   
   // Getter methods
   int GetSupportPointsCount() { return ArraySize(currDaySupportPoints); }
   int GetResistancePointsCount() { return ArraySize(currDayResistancePoints); }
   SRPoint GetSupportPoint(int index);
   SRPoint GetResistancePoint(int index);
   
   // Setter methods
   void SetMargin(double newMargin) { margin = newMargin; }
   void SetZigZagParameters(int depth, int deviation, int backstep);

   int GetP(); 
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSupportResistance::CSupportResistance(double marginPips = 10.0, int depth = 12, int deviation = 5, int backstep = 3)
{
   margin = marginPips * P * Point; // convert to price 
   zigzagDepth = depth;
   zigzagDeviation = deviation;
   zigzagBackstep = backstep;

   P = GetP(); // Get Pips to Points conversion factor
   
   linePrefix = "SR_Line_";
   lineCounter = 0;
   
   prevDayHighest = 0;
   prevDayLowest = 0;
   prevDayStart = 0;
   currDayStart = 0;
   
   ArrayResize(currDaySupportPoints, 0);
   ArrayResize(currDayResistancePoints, 0);
   ArrayResize(currDaySRpoints, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSupportResistance::~CSupportResistance()
{
//    ClearCurrentDayLines();
}

//+------------------------------------------------------------------+
//| Main update method called on every new bar                      |
//+------------------------------------------------------------------+
void CSupportResistance::SRUpdate(int i)
{
   datetime barTime = Time[i];
   datetime newDayStart = GetDayStart(barTime);
   
   // Check if it's a new day
   if (currDayStart != newDayStart)
   {
      // Update previous day extremes before clearing
      if (currDayStart == 0)
      {
         FindPreviousDayExtremes(newDayStart - 86400); // Find previous day extremes
      } 
      else
      {
        FindPreviousDayExtremes(currDayStart);
      }
      
      currDayStart = newDayStart;
   }
   
   ClearCurrentDayLines(currDayStart);
   ClearCurrentDayPoints();
   
   // Find ZigZag points for current day
   FindZigZagPoints(currDayStart, barTime);
   
   // Draw lines for current day support and resistance points
   for (int j = 0; j < ArraySize(currDaySupportPoints); j++)
   {
      string lineName = linePrefix + "Support_" + TimeToString(currDayStart, TIME_DATE) + "_" + IntegerToString(lineCounter++);
      DrawHorizontalLine(lineName, currDaySupportPoints[j].price, currDaySupportPoints[j].time, barTime, clrBlue);
   }
   
   for (int j = 0; j < ArraySize(currDayResistancePoints); j++)
   {
      string lineName = linePrefix + "Resistance_" + TimeToString(currDayStart, TIME_DATE) + "_"  + IntegerToString(lineCounter++);
      DrawHorizontalLine(lineName, currDayResistancePoints[j].price, currDayResistancePoints[j].time, barTime, clrBlue);
   }
   
   // Draw previous day extreme lines if available
   if (prevDayHighest > 0)
   {
      string lineNameHigh = linePrefix + "PrevHigh_" + TimeToString(currDayStart, TIME_DATE) + "_"  + IntegerToString(lineCounter++);
      DrawHorizontalLine(lineNameHigh, prevDayHighest, currDayStart, barTime, clrGreen);
      
      // Add to currDaySRpoints
      int size = ArraySize(currDaySRpoints);
      ArrayResize(currDaySRpoints, size + 1);
      currDaySRpoints[size] = SRPoint(prevDayHighest, currDayStart, false);
   }
   
   if (prevDayLowest > 0)
   {
      string lineNameLow = linePrefix + "PrevLow_" + TimeToString(currDayStart, TIME_DATE) + "_"  + IntegerToString(lineCounter++);
      DrawHorizontalLine(lineNameLow, prevDayLowest, currDayStart, barTime, clrRed);
      
      // Add to currDaySRpoints
      int size = ArraySize(currDaySRpoints);
      ArrayResize(currDaySRpoints, size + 1);
      currDaySRpoints[size] = SRPoint(prevDayLowest, currDayStart, true);
   }
}

//+------------------------------------------------------------------+
//| Check if price is near support or resistance                    |
//+------------------------------------------------------------------+
SR_STATUS CSupportResistance::CheckNearSR(double price, datetime time, SR_TREND_TYPE trend)
{
   // Check against current day support points
   for (int i = 0; i < ArraySize(currDaySupportPoints); i++)
   {
      double priceDiff = currDaySupportPoints[i].price - price;
      
      if (trend == SR_UP_TREND)
      {
         if (priceDiff > margin)
            return BELOW_RESISTANCE;
         else if (MathAbs(priceDiff) <= margin)
            return ABOVE_RESISTANCE;
      }
      else if (trend == SR_DOWN_TREND)
      {
         if (priceDiff < -margin)
            return ABOVE_SUPPORT;
         else if (MathAbs(priceDiff) <= margin)
            return BELOW_SUPPORT;
      }
   }
   
   // Check against current day resistance points
   for (int i = 0; i < ArraySize(currDayResistancePoints); i++)
   {
      double priceDiff = currDayResistancePoints[i].price - price;
      
      if (trend == SR_UP_TREND)
      {
         if (priceDiff > margin)
            return BELOW_RESISTANCE;
         else if (MathAbs(priceDiff) <= margin)
            return ABOVE_RESISTANCE;
      }
      else if (trend == SR_DOWN_TREND)
      {
         if (priceDiff < -margin)
            return ABOVE_SUPPORT;
         else if (MathAbs(priceDiff) <= margin)
            return BELOW_SUPPORT;
      }
   }
   
   // Check against previous day extreme points
   for (int i = 0; i < ArraySize(currDaySRpoints); i++)
   {
      double priceDiff = currDaySRpoints[i].price - price;
      
      if (trend == SR_UP_TREND)
      {
         if (priceDiff > margin)
            return BELOW_RESISTANCE;
         else if (MathAbs(priceDiff) <= margin)
            return ABOVE_RESISTANCE;
      }
      else if (trend == SR_DOWN_TREND)
      {
         if (priceDiff < -margin)
            return ABOVE_SUPPORT;
         else if (MathAbs(priceDiff) <= margin)
            return BELOW_SUPPORT;
      }
   }
   
   return NOT_NEAR_SR;
}

//+------------------------------------------------------------------+
//| Helper method to check if it's a new day                        |
//+------------------------------------------------------------------+
bool CSupportResistance::IsNewDay(datetime currentTime, datetime previousTime)
{
   return TimeDay(currentTime) != TimeDay(previousTime) || 
          TimeMonth(currentTime) != TimeMonth(previousTime) || 
          TimeYear(currentTime) != TimeYear(previousTime);
}

//+------------------------------------------------------------------+
//| Clear all current day lines                                     |
//+------------------------------------------------------------------+
void CSupportResistance::ClearCurrentDayLines(datetime dayStart)
{
   // Remove all lines with our prefix
   for (int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string objName = ObjectName(i);
      if (StringFind(objName, TimeToString(dayStart)) == 0)
      {
         ObjectDelete(objName);
      }
   }
   
   lineCounter = 0;
}

//+------------------------------------------------------------------+
//| Clear current day support and resistance points                 |
//+------------------------------------------------------------------+
void CSupportResistance::ClearCurrentDayPoints()
{
   ArrayResize(currDaySupportPoints, 0);
   ArrayResize(currDayResistancePoints, 0);
   ArrayResize(currDaySRpoints, 0);
}

//+------------------------------------------------------------------+
//| Draw horizontal line                                             |
//+------------------------------------------------------------------+
void CSupportResistance::DrawHorizontalLine(string name, double price, datetime startTime, datetime endTime, color lineColor, int width = 1)
{
   ObjectDelete(name);
   ObjectCreate(name, OBJ_TREND, 0, startTime, price, endTime, price);
   ObjectSet(name, OBJPROP_COLOR, lineColor);
   ObjectSet(name, OBJPROP_WIDTH, width);
   ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(name, OBJPROP_RAY, false);
   ObjectSet(name, OBJPROP_BACK, true);
}

//+------------------------------------------------------------------+
//| Find ZigZag points for the specified time period                |
//+------------------------------------------------------------------+
void CSupportResistance::FindZigZagPoints(datetime dayStart, datetime dayEnd)
{
   int startBar = iBarShift(Symbol(), Period(), dayStart);
   int endBar = iBarShift(Symbol(), Period(), dayEnd);
   
   if (startBar < 0) startBar = Bars - 1;
   if (endBar < 0) endBar = 0;
   
   // Search for ZigZag points from start to end of day
   for (int i = startBar; i >= endBar; i--)
   {
      double zigzagValue = iCustom(Symbol(), Period(), "ZigZag", zigzagDepth, zigzagDeviation, zigzagBackstep, 0, i);
      
      if (zigzagValue != 0 && zigzagValue != EMPTY_VALUE)
      {
         // Determine if this is a high or low point
         bool isHigh = (zigzagValue == High[i]);
         
         if (isHigh)
         {
            // Add to resistance points
            int size = ArraySize(currDayResistancePoints);
            ArrayResize(currDayResistancePoints, size + 1);
            currDayResistancePoints[size] = SRPoint(zigzagValue, Time[i], false);
         }
         else
         {
            // Add to support points
            int size = ArraySize(currDaySupportPoints);
            ArrayResize(currDaySupportPoints, size + 1);
            currDaySupportPoints[size] = SRPoint(zigzagValue, Time[i], true);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Find previous day extreme values                                |
//+------------------------------------------------------------------+
void CSupportResistance::FindPreviousDayExtremes(datetime dayStart)
{
   datetime dayEnd = dayStart + 86400; // Add one day
   
   int startBar = iBarShift(Symbol(), Period(), dayStart);
   int endBar = iBarShift(Symbol(), Period(), dayEnd);
   
   if (startBar < 0) return;
   if (endBar < 0) endBar = 0;
   
   prevDayHighest = 0;
   prevDayLowest = 999999;
   
   // Find highest and lowest ZigZag points from previous day
   for (int i = startBar; i >= endBar; i--)
   {
      double zigzagValue = iCustom(Symbol(), Period(), "ZigZag", zigzagDepth, zigzagDeviation, zigzagBackstep, 0, i);
      
      if (zigzagValue != 0 && zigzagValue != EMPTY_VALUE)
      {
         if (zigzagValue > prevDayHighest)
            prevDayHighest = zigzagValue;
         if (zigzagValue < prevDayLowest)
            prevDayLowest = zigzagValue;
      }
   }
   
   // If no ZigZag points found, use High/Low of the day
   if (prevDayHighest == 0)
   {
      for (int i = startBar; i >= endBar; i--)
      {
         if (High[i] > prevDayHighest)
            prevDayHighest = High[i];
         if (prevDayLowest == 999999 || Low[i] < prevDayLowest)
            prevDayLowest = Low[i];
      }
   }
}

//+------------------------------------------------------------------+
//| Get start of day                                                 |
//+------------------------------------------------------------------+
datetime CSupportResistance::GetDayStart(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Get end of day                                                   |
//+------------------------------------------------------------------+
datetime CSupportResistance::GetDayEnd(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   dt.hour = 23;
   dt.min = 59;
   dt.sec = 59;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Get support point by index                                      |
//+------------------------------------------------------------------+
SRPoint CSupportResistance::GetSupportPoint(int index)
{
   if (index >= 0 && index < ArraySize(currDaySupportPoints))
      return currDaySupportPoints[index];
   return SRPoint();
}

//+------------------------------------------------------------------+
//| Get resistance point by index                                   |
//+------------------------------------------------------------------+
SRPoint CSupportResistance::GetResistancePoint(int index)
{
   if (index >= 0 && index < ArraySize(currDayResistancePoints))
      return currDayResistancePoints[index];
   return SRPoint();
}

//+------------------------------------------------------------------+
//| Set ZigZag parameters                                            |
//+------------------------------------------------------------------+
void CSupportResistance::SetZigZagParameters(int depth, int deviation, int backstep)
{
   zigzagDepth = depth;
   zigzagDeviation = deviation;
   zigzagBackstep = backstep;
}

int CSupportResistance::GetP() 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns P, which is used for converting pips to decimals/points

   int output;
   if(Digits==5 || Digits==3) output=10;else output=1;
   return(output);

/* Some definitions: Pips vs Point

1 pip = 0.0001 on a 4 digit broker and 0.00010 on a 5 digit broker
1 point = 0.0001 on 4 digit broker and 0.00001 on a 5 digit broker
  
*/

  }