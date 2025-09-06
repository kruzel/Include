//+-------------------------------------------------------------------+
//|                                           02_OrderProfitToCSV.mqh |
//|                                  Copyright 2018, Vladimir Zhbanko |
//+-------------------------------------------------------------------+
#property copyright "Copyright 2020, Vladimir Zhbanko"
#property link      "https://vladdsm.github.io/myblog_attempt/"
#property strict
#property version   "3.00"
// function to write order profits to csv using EA
// version 01
// date 31.07.2016
// version 02 - added order symbol for ticket
// date 25.12.2016
// version 03 - added function DoubleToString
//+-------------------------------------------------------------+//
//Function requires just input of the trade terminal number      //
//+-------------------------------------------------------------+//
/*
This function scroll through the number of previously set orders by function GetHistoryOrderByCloseTime
User guide:
1. Add extern variable to EA: e.g.:                     extern int     TradeTermNumber   = 2;
2. Add function call inside start function to EA: e.g.: OrderProfitToCSV(TradeTermNumber);
3. Add include call to this file  to EAe.g.:            #include <02_OrderProfitToCSV.mqh>
*/
//+------------------------------------------------------------------+
//| FUNCTION ORDER PROFIT TO CSV
//+------------------------------------------------------------------+
void OrderProfitToCSV(int terminalNumber)
{
   //*3*_Logging closed orders to the file csv for further order management in R
    int  tickets[], nTickets = GetHistoryOrderByCloseTime(tickets, MagicNumber);  // this define dyn. array with tickets, gets ticket num in history
    static int prevAmountTickets = 0;       // variable used for order history logging

    // Check if file exists and has content (titles)
    string currentDate = TimeToStr(TimeCurrent(), TIME_DATE);
    string fileName = "OrdersResultsT_" + string(MagicNumber) + "_" + string(terminalNumber) + ".csv";
    bool fileExists = false;
    
    // Check if file exists by trying to open it for reading
    int testHandle = FileOpen(fileName,FILE_CSV|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE);
    if (testHandle != INVALID_HANDLE)
    {
      fileExists = (FileSize(testHandle) > 0);
      FileClose(testHandle);
    }

    // If file doesn't exist or is empty, write headers
    if (!fileExists)
    {
      int headerHandle = FileOpen(fileName,FILE_CSV|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE);
      if (headerHandle != INVALID_HANDLE)
      {
        string headers = "MagicNumber,Ticket,OpenTime,CloseTime,Profit,Symbol,OrderType,SMA20,EMA20,RSI14,StochMain,StochSignal,BBUpper,BBMiddle,BBLower,MFI14,OBV,CCI14";
        FileWrite(headerHandle, headers);
        FileClose(headerHandle);
      }
    }
    
    for(int iTicket = nTickets - prevAmountTickets - 1; iTicket >= 0; iTicket--)  // starting for loop in order to scroll through each ticket
      {
        if (OrderSelect(tickets[iTicket], SELECT_BY_TICKET))                      // getting ticket number by selecting elements of array
         {
           if (OrderCloseTime() < ReferenceTime ) break;                          // stop scrolling if time of order is less then reference time defined onInit()
                 // recover info needed
                 double  profit  = OrderProfit() + OrderSwap() + OrderCommission();
                 string ordPair  = OrderSymbol();
                 // Technical indicators at order close time
                 double sma20 = iMA(ordPair, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
                 double ema20 = iMA(ordPair, PERIOD_CURRENT, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
                 double rsi14 = iRSI(ordPair, PERIOD_CURRENT, 14, PRICE_CLOSE, 0);
                 double stochMain = iStochastic(ordPair, PERIOD_CURRENT, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
                 double stochSignal = iStochastic(ordPair, PERIOD_CURRENT, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 0);
                 double bbUpper = iBands(ordPair, PERIOD_CURRENT, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
                 double bbMiddle = iBands(ordPair, PERIOD_CURRENT, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, 0);
                 double bbLower = iBands(ordPair, PERIOD_CURRENT, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
                 double mfi14 = iMFI(ordPair, PERIOD_CURRENT, 14, 0);
                 double obv = iOBV(ordPair, PERIOD_CURRENT, PRICE_CLOSE, 0);
                 double cci14 = iCCI(ordPair, PERIOD_CURRENT, 14, PRICE_TYPICAL, 0);
                 int     ordTyp  = OrderType();
                 datetime ordOT  = OrderOpenTime();
                 datetime ordCT  = OrderCloseTime();
                 int  ordTicket  = OrderTicket();
                 
                 // Open file for appending data
                 int dataHandle = FileOpen(fileName,FILE_CSV|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE);
                 if (dataHandle != INVALID_HANDLE)
                 {
                   FileSeek(dataHandle, 0, SEEK_END);
                   string data = string(MagicNumber) + "," + string(ordTicket) + "," + string(ordOT) + "," + string(ordCT) + ","
                   + DoubleToStr(profit,2)+ ","+ordPair+","+string(ordTyp) + "," + DoubleToStr(sma20,5) + "," + DoubleToStr(ema20,5) + ","
                   + DoubleToStr(rsi14,2) + "," + DoubleToStr(stochMain,2) + "," + DoubleToStr(stochSignal,2) + ","
                   + DoubleToStr(bbUpper,5) + "," + DoubleToStr(bbMiddle,5) + "," + DoubleToStr(bbLower,5) + ","
                   + DoubleToStr(mfi14,2) + "," + DoubleToStr(obv,0) + "," + DoubleToStr(cci14,2);
                   FileWrite(dataHandle, data);   //write data to the file during each for loop iteration
                   FileClose(dataHandle);        //close file when data write is over
                 }
         }  
      }
          prevAmountTickets = nTickets; //defining previous amount of tickets to avoid double entries!
}

