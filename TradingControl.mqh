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
      tradingEnabled = false;
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
      int chartColor =  ChartGetInteger(0, CHART_COLOR_BACKGROUND);
      // Panel background
      frameName = "TradingControlPanelBG";
      if(ObjectFind(0, frameName) < 0)
        {
         ObjectCreate(0, frameName, OBJ_RECTANGLE_LABEL , 0, 0, 0);
         ObjectSetInteger(0, frameName, OBJPROP_XDISTANCE, 200);
         ObjectSetInteger(0, frameName, OBJPROP_YDISTANCE, 10);
         ObjectSetInteger(0, frameName, OBJPROP_XSIZE, 130);
         ObjectSetInteger(0, frameName, OBJPROP_YSIZE, 180);
         ObjectSetInteger(0, frameName, OBJPROP_CORNER, 0);
         
         if(chartColor == clrWhite)
         {
          ObjectSetInteger(0, frameName, OBJPROP_BGCOLOR, clrBlack);
          ObjectSetInteger(0, frameName, OBJPROP_COLOR, clrWhite);
         }
        else
        {
          ObjectSetInteger(0, frameName, OBJPROP_BGCOLOR, clrWhite);
          ObjectSetInteger(0, frameName, OBJPROP_COLOR, clrBlack);
        } 
         ObjectSetInteger(0, frameName, OBJPROP_BACK, false);
        }

      // Title label
      labelName = "AutoTradingLabel";
      if(ObjectFind(0, labelName) < 0)
        {
         ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 215);
         ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, 20);
         ObjectSetInteger(0, labelName, OBJPROP_CORNER, 0);
         ObjectSetString(0, labelName, OBJPROP_TEXT, " AutoTrading ");
         ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
         if(chartColor == clrWhite)
          ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrWhite);
         else
          ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrBlack);
        }

      // AutoTrading button
      if(ObjectFind(0, buttonOnName) < 0)
        {
         ObjectCreate(0, buttonOnName, OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, buttonOnName, OBJPROP_XDISTANCE, 210);
         ObjectSetInteger(0, buttonOnName, OBJPROP_YDISTANCE, 45);
         ObjectSetInteger(0, buttonOnName, OBJPROP_XSIZE, 110);
         ObjectSetInteger(0, buttonOnName, OBJPROP_YSIZE, 25);
         ObjectSetString(0, buttonOnName, OBJPROP_TEXT, "  Disabled  ");
         ObjectSetInteger(0, buttonOnName, OBJPROP_CORNER, 0);
         ObjectSetInteger(0, buttonOnName, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, buttonOnName, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(0, buttonOnName, OBJPROP_ALIGN, ALIGN_CENTER);
         ObjectSetInteger(0, buttonOnName, OBJPROP_STATE, tradingEnabled);
        }

      // Win Target label
      string winTargetLabel = "WinTargetLabel";
      if(ObjectFind(0, winTargetLabel) < 0)
        {
         ObjectCreate(0, winTargetLabel, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, winTargetLabel, OBJPROP_XDISTANCE, 215);
         ObjectSetInteger(0, winTargetLabel, OBJPROP_YDISTANCE, 85);
         ObjectSetString(0, winTargetLabel, OBJPROP_TEXT, "Win Target %:");
         ObjectSetInteger(0, winTargetLabel, OBJPROP_FONTSIZE, 10);
         ObjectSetInteger(0, winTargetLabel, OBJPROP_COLOR, clrBlack);
         if(chartColor == clrWhite)
          ObjectSetInteger(0, winTargetLabel, OBJPROP_COLOR, clrWhite);
         else
          ObjectSetInteger(0, winTargetLabel, OBJPROP_COLOR, clrBlack);
        }

      // Win Target edit
      string winTargetEdit = "WinTargetEdit";
      if(ObjectFind(0, winTargetEdit) < 0)
        {
         ObjectCreate(0, winTargetEdit, OBJ_EDIT, 0, 0, 0);
         ObjectSetInteger(0, winTargetEdit, OBJPROP_XDISTANCE, 210);
         ObjectSetInteger(0, winTargetEdit, OBJPROP_YDISTANCE, 105);
         ObjectSetInteger(0, winTargetEdit, OBJPROP_XSIZE, 110);
         ObjectSetInteger(0, winTargetEdit, OBJPROP_YSIZE, 22);
         ObjectSetString(0, winTargetEdit, OBJPROP_TEXT, "3.0");
         if(chartColor == clrWhite)
         {
          ObjectSetInteger(0, winTargetEdit, OBJPROP_COLOR, clrBlack);
          ObjectSetInteger(0, winTargetEdit, OBJPROP_BGCOLOR, clrWhite);
         }
         else
         {
          ObjectSetInteger(0, winTargetEdit, OBJPROP_COLOR, clrWhite);
          ObjectSetInteger(0, winTargetEdit, OBJPROP_BGCOLOR, clrBlack);
         }
        }

      // Loss Target label
      string lossTargetLabel = "LossTargetLabel";
      if(ObjectFind(0, lossTargetLabel) < 0)
        {
         ObjectCreate(0, lossTargetLabel, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, lossTargetLabel, OBJPROP_XDISTANCE, 215);
         ObjectSetInteger(0, lossTargetLabel, OBJPROP_YDISTANCE, 135);
         ObjectSetString(0, lossTargetLabel, OBJPROP_TEXT, "Loss Target %:");
         ObjectSetInteger(0, lossTargetLabel, OBJPROP_FONTSIZE, 10);
         if(chartColor == clrWhite)
          ObjectSetInteger(0, lossTargetLabel, OBJPROP_COLOR, clrWhite);
         else
          ObjectSetInteger(0, lossTargetLabel, OBJPROP_COLOR, clrBlack);
        }

      // Loss Target edit
      string lossTargetEdit = "LossTargetEdit";
      if(ObjectFind(0, lossTargetEdit) < 0)
        {
         ObjectCreate(0, lossTargetEdit, OBJ_EDIT, 0, 0, 0);
         ObjectSetInteger(0, lossTargetEdit, OBJPROP_XDISTANCE, 210);
         ObjectSetInteger(0, lossTargetEdit, OBJPROP_YDISTANCE, 155);
         ObjectSetInteger(0, lossTargetEdit, OBJPROP_XSIZE, 110);
         ObjectSetInteger(0, lossTargetEdit, OBJPROP_YSIZE, 22);
         ObjectSetString(0, lossTargetEdit, OBJPROP_TEXT, "-3.0");
         if(chartColor == clrWhite)
         {
          ObjectSetInteger(0, lossTargetEdit, OBJPROP_COLOR, clrBlack);
          ObjectSetInteger(0, lossTargetEdit, OBJPROP_BGCOLOR, clrWhite);
         }
         else
         {
          ObjectSetInteger(0, lossTargetEdit, OBJPROP_COLOR, clrWhite);
          ObjectSetInteger(0, lossTargetEdit, OBJPROP_BGCOLOR, clrBlack);
         }
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

    double GetWinTarget()
     {
      return StringToDouble(ObjectGetString(0, "WinTargetEdit", OBJPROP_TEXT));
     }

    double GetLossTarget()
     {
      return StringToDouble(ObjectGetString(0, "LossTargetEdit", OBJPROP_TEXT));
     }
  };
//+------------------------------------------------------------------+
