#ifndef OBJPROP_WIDTH
#define OBJPROP_WIDTH 100
#endif
#ifndef OBJPROP_HEIGHT
#define OBJPROP_HEIGHT 101
#endif
#ifndef OBJPROP_TEXTCOLOR
#define OBJPROP_TEXTCOLOR 243
#endif
#ifndef ALIGN_TOP
#define ALIGN_TOP 1
#endif
#include <stderror.mqh>

//+------------------------------------------------------------------+
//| CTradingControl.mqh                                               |
//| Class to control trading On/Off via chart buttons                |
//+------------------------------------------------------------------+
class CTradingControl
  {
private:
   bool tradingEnabled;
   int buttonOnId;
   string frameName;
   string labelName;
   string buttonOnName;

public:
   CTradingControl()
     {
      tradingEnabled = true;
      buttonOnId = 10001;
      buttonOnName = "AutoTradingBtn";
     }

   ~CTradingControl()
    {
        ObjectDelete(0, buttonOnName);
        ObjectDelete(0, frameName);
        ObjectDelete(0, labelName);
    }

   void CreateButton()
     {
      // Create frame
      frameName = "TradingControler";
      if(ObjectFind(0, frameName) < 0)
        {
         ObjectCreate(0, frameName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         ObjectSetInteger(0, frameName, OBJPROP_XDISTANCE, 205);
         ObjectSetInteger(0, frameName, OBJPROP_YDISTANCE, 5);
         ObjectSetInteger(0, frameName, OBJPROP_XSIZE, 110);
         ObjectSetInteger(0, frameName, OBJPROP_YSIZE, 50);
         ObjectSetInteger(0, frameName, OBJPROP_CORNER, 0);
         ObjectSetInteger(0, frameName, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(0, frameName, OBJPROP_BACK, false);
         ObjectSetInteger(0, frameName, OBJPROP_BORDER_TYPE, BORDER_RAISED);
        }

      labelName = "AutoTradingLabel";
      if(ObjectFind(0, labelName) < 0)
        {
         ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 220); // Center in frame (205 + 110/2 = 260)
         ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, 10);  // Above button (button at Y=30, label at Y=15)
         ObjectSetInteger(0, labelName, OBJPROP_CORNER, 0);
         ObjectSetString(0, labelName, OBJPROP_TEXT, " AutoTrading ");
         ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrBlack);
        }
        
      // Create AutoTrading button inside the frame
      if(ObjectFind(0, buttonOnName) < 0)
        {
         ObjectCreate(0, buttonOnName, OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, buttonOnName, OBJPROP_XDISTANCE, 210); // Frame starts at 205, button at 210 (5px margin)
         ObjectSetInteger(0, buttonOnName, OBJPROP_YDISTANCE, 30);  // Frame starts at 5, button at 10 (5px margin)
         ObjectSetInteger(0, buttonOnName, OBJPROP_XSIZE, 100);     // Frame width 190, button 60 (5px margin each side)
         ObjectSetInteger(0, buttonOnName, OBJPROP_YSIZE, 20);     // Frame height 50, button 20 (5px margin each side)
         ObjectSetString(0, buttonOnName, OBJPROP_TEXT, "  Enabled  "); // Add margin with spaces
         ObjectSetInteger(0, buttonOnName, OBJPROP_CORNER, 5);
         ObjectSetInteger(0, buttonOnName, OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, buttonOnName, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(0, buttonOnName, OBJPROP_ALIGN, ALIGN_CENTER);
        ObjectSetInteger(0, buttonOnName, OBJPROP_STATE, true);
        }
     }

   void CheckButtonClick()
     {
      if(ObjectGetInteger(0, buttonOnName, OBJPROP_TYPE) == OBJ_BUTTON)
        {
         bool state = ObjectGetInteger(0, buttonOnName, OBJPROP_STATE);
         tradingEnabled = state;
         
         // Update button color based on state
         if(state)
           {
            ObjectSetString(0, buttonOnName, OBJPROP_TEXT, "  Enabled  ");
            ObjectSetInteger(0, buttonOnName, OBJPROP_COLOR, clrGreen);
            Print("AutoTrading enabled by user.");
           }
         else
           {
            ObjectSetString(0, buttonOnName, OBJPROP_TEXT, "  Disabled  ");
            ObjectSetInteger(0, buttonOnName, OBJPROP_COLOR, clrRed);
            Print("AutoTrading disabled by user.");
           }
         ChartRedraw();
        }
     }

   bool IsTradingEnabled()
     {
      return tradingEnabled;
     }
  };
//+------------------------------------------------------------------+
