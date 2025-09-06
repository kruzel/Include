//+------------------------------------------------------------------+
//|                                           01_GetHistoryOrder.mqh |
//|                                 Copyright 2018, Vladimir Zhbanko |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Vladimir Zhbanko"
#property link      "https://vladdsm.github.io/myblog_attempt/"
#property strict
// function to handle history in EA's
// source: https://www.mql5.com/en/forum/138127

//+---------------------------------------------------+//
//Function returning n of orders in history            //
//+---------------------------------------------------+//
/*
This function goes to the past orders and finds the number of closed orders in the history
It returns the number of orders in the history that will be used for the caller variable
User guide:
1. Add extern variable to EA: e.g.:                     extern int     MagicNumber   = 6100100;
2. Add global variable to EA: e.g.:                     datetime ReferenceTime;
3. Add code inside init() function e.g.:                ReferenceTime = TimeCurrent(); 
4. Add function call inside start function to EA: e.g.: OrderProfitToCSV(TradeTermNumber);
5. Add include call to this file  to EAe.g.:            #include <01_HistoryFunction.mqh>
6. Add include call to this file  to EAe.g.:            #include <02_OrderProfitToCSV.mqh>


*/
int GetHistoryOrderByCloseTime(int& tickets[], int Magic, int dsc=1){  #define ASCENDING -1
    /* https://forum.mql4.com/46182 zzuegg says history ordering "is not reliable
     * (as said in the doc)" [not in doc] dabbler says "the order of entries is
     * mysterious (by actual test)" */
    int nOrders = 0, iOrders;    datetime OCTs[];                                   // defining needed variables
    for (int iPos=OrdersHistoryTotal()-1; iPos >= 0; iPos--)                        // for loop to scrol through all positions in history
       {
          if (OrderSelect(iPos, SELECT_BY_POS, MODE_HISTORY) &&                     // Only orders w/
              OrderMagicNumber()  == Magic &&                                       // my magic number
              OrderType()         <= OP_SELL)                                       // Avoid cr/bal forum.mql4.com/32363#325360
             {
                int      nextTkt = OrderTicket();                                   // Once the ticket is selected we save it's number to nextTkt var
                datetime nextOCT = OrderCloseTime();                                // We also select the time this order was closed
                nOrders++;                                                          // Our objective was to have number of orders done by this EA...
                ArrayResize(tickets,nOrders);                                       // Increase array size containing the tickets numbers
                ArrayResize(OCTs,nOrders);                                          // Increase array size containing the tickets close timings
                  for (iOrders = nOrders - 1; iOrders > 0; iOrders--)               // This for loop need to manipulate through the "previous" ticket
                     {  // Insertn sort.
                          datetime    prevOCT     = OCTs[iOrders-1];                // Define the time when previous order was closed using the info from array
                          if ((prevOCT - nextOCT) * dsc >= 0)     break;            // interrupt when we deal with the order that is last one
                          int  prevTkt = tickets[iOrders-1];                        // Define the previous ticket number using info from array
                          tickets[iOrders] = prevTkt;                               // Save ticket number to array
                          OCTs[iOrders]    = prevOCT;                               // Save ticket time to array
                     }
                tickets[iOrders] = nextTkt;                                         // Finally insert the next ticket number
                OCTs[iOrders] = nextOCT;                                            // Insert the next ticket close time
             }
       }            
    return(nOrders); 
}

int GetHistoryOrderByCloseTime(int& tickets[],datetime& OCTs[], double& profits[], int Magic, int dsc=1){  #define ASCENDING -1
    /* https://forum.mql4.com/46182 zzuegg says history ordering "is not reliable
     * (as said in the doc)" [not in doc] dabbler says "the order of entries is
     * mysterious (by actual test)" */
    int nOrders = 0, iOrders;                                                       // defining needed variables

    for (int iPos=OrdersHistoryTotal()-1; iPos >= 0; iPos--)                        // for loop to scrol through all positions in history
       {
          if (OrderSelect(iPos, SELECT_BY_POS, MODE_HISTORY) &&                     // Only orders w/
              OrderMagicNumber()  == Magic &&                                       // my magic number
              OrderType()         <= OP_SELL &&
              OrderSymbol() == Symbol())                                       // Avoid cr/bal forum.mql4.com/32363#325360
             {
                int      nextTkt = OrderTicket();                                   // Once the ticket is selected we save it's number to nextTkt var
                datetime nextOCT = OrderCloseTime();  
                double   nextProfit = OrderProfit();                                // We also select the time this order was closed
                nOrders++;                                                          // Our objective was to have number of orders done by this EA...
                ArrayResize(tickets,nOrders);                                       // Increase array size containing the tickets numbers
                ArrayResize(OCTs,nOrders);      
                ArrayResize(profits,nOrders);                                       // Increase array size containing the tickets close timings
                  for (iOrders = nOrders - 1; iOrders > 0; iOrders--)               // This for loop need to manipulate through the "previous" ticket
                     {  // Insertn sort.
                          datetime    prevOCT     = OCTs[iOrders-1];                // Define the time when previous order was closed using the info from array
                          if ((prevOCT - nextOCT) * dsc >= 0)     break;            // interrupt when we deal with the order that is last one
                          int  prevTkt = tickets[iOrders-1];                        // Define the previous ticket number using info from array
                          tickets[iOrders] = prevTkt;                               // Save ticket number to array
                          OCTs[iOrders]    = prevOCT;                               // Save ticket time to array
                          profits[iOrders] = nextProfit;                             // Save ticket profit to array
                     }
                tickets[iOrders] = nextTkt;                                         // Finally insert the next ticket number
                OCTs[iOrders] = nextOCT;                                          // Insert the next ticket close time
                profits[iOrders] = nextProfit;                                    // Insert the next ticket profit
             }
       }            
    return(nOrders); 
}

//+------------------------------------------------------------------+
//| Get start of day                                                 |
//+------------------------------------------------------------------+
datetime GetDayStart(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Get Total Loss Amount from Consecutive Failures                  |
//+------------------------------------------------------------------+
double GetConsecutiveLossAmount(int Magic, int& consecutiveLosses)
{
    double totalLoss = 0;
    consecutiveLosses = 0;
    
    // Get today's start time (start of current day)
    datetime currentTime = TimeCurrent();
    datetime todayStart = currentTime - (currentTime % 86400); // 86400 = seconds in a day
    
    // Check order history from most recent backwards
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
            if(OrderSymbol() == Symbol() && 
               OrderMagicNumber() == Magic && 
               // OrderCloseTime() >= todayStart &&
               (OrderType() == OP_BUY || OrderType() == OP_SELL))
            {
                double profit = OrderProfit() + OrderSwap() + OrderCommission();
                
                if(profit < 0)
                {
                    totalLoss += profit; // Add negative profit (loss)
                    consecutiveLosses++;
                }
                else
                {
                    break; // Stop at first profitable trade
                }
            }
        }
    }
    
    return totalLoss;
}
//+------------------------------------------------------------------+
//| Get Total Loss Amount from Consecutive Failures                  |
//+------------------------------------------------------------------+
//| Function returning number of consecutive failures           |
//+------------------------------------------------------------------+
double GetConsecutiveFailureCount(int Magic)
{
    int failureCount = 0;
    double lossAmount = GetConsecutiveLossAmount(Magic, failureCount); 
    
    return failureCount;
}

enum CloseReason
{
    None,
    StopLoss,
    TakeProfit,
    Manual
};

bool GetBarProfitByTime(datetime time, int Magic, double& profit, int& type, double& price, CloseReason& closeReason, string symbol)
{
    profit = 0;
    type = -1;
    price = 0;

    // Loop through all closed orders
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         {
              // Check if the order is from the specified magic number
              if(OrderMagicNumber() == Magic && symbol == OrderSymbol())
              {
                    // Check if the order was closed at the specified time
                    if(OrderCloseTime() == time)
                    {
                         profit = OrderProfit();
                         type = OrderType();
                         price = OrderClosePrice();
                          // Get the close reason
                          if(OrderProfit() < 0 && MathAbs(OrderClosePrice() - OrderStopLoss()) < Point)
                          {
                               closeReason = StopLoss;
                          }
                          else if(OrderProfit() > 0 && MathAbs(OrderClosePrice() - OrderTakeProfit()) < Point)
                          {
                               closeReason = TakeProfit;
                          }
                          else
                          {
                               closeReason = Manual;
                          }
                          return true; // Return true if we found the order
                    }
              }
         }
    }

    return false; // Return false if we didn't find the order
}

double GetProfitToday(int Magic, string symbol)
{
    double totalProfit = 0;

    // Loop through all closed orders
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         {
              // Check if the order is from the specified magic number
              if(OrderMagicNumber() == Magic && symbol == OrderSymbol())
              {
                   // Check if the order was closed today
                   if(OrderCloseTime() >= GetDayStart(TimeCurrent()))
                   {
                        totalProfit += OrderProfit();
                   }
              }
         }
    }

    return totalProfit;
}

double GetTotalProfit(int Magic, string symbol)
{
    double totalProfit = 0;

    // Loop through all closed orders
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         {
              // Check if the order is from the specified magic number
              if(OrderMagicNumber() == Magic && symbol == OrderSymbol())
              {
                   totalProfit += OrderProfit();
              }
         }
    }

    return totalProfit;
}

int GetLastClosedOrderToday(int Magic, string symbol)
{
     int lastOrder = 0;
     datetime lastCloseTime = 0;

     // Loop through all closed orders
     for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
     {
          if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
          {
               // Check if the order is from the specified magic number
               if(OrderMagicNumber() == Magic && symbol == OrderSymbol())
               {
                    // Check if this order was closed today and later than the previous one
                    if(OrderCloseTime() >= GetDayStart(TimeCurrent()) && OrderCloseTime() > lastCloseTime)
                    {
                         lastCloseTime = OrderCloseTime();
                         lastOrder = OrderTicket();
                    }
               }
          }
     }

     return lastOrder;
}

int GetLastOpenOrder(int Magic, string symbol)
{
     int lastOrder = 0;
     datetime lastOpenTime = 0;

     // Loop through all open orders
     for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
          if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
          {
               // Check if the order is from the specified magic number
               if(OrderMagicNumber() == Magic && symbol == OrderSymbol())
               {
                    // Check if this order was opened later than the previous one
                    if(OrderOpenTime() > lastOpenTime)
                    {
                         lastOpenTime = OrderOpenTime();
                         lastOrder = OrderTicket();
                    }
               }
          }
     }

     return lastOrder;
}

bool GetLastProfit(int Magic, int& order, datetime& time, double& profit, int& type, double& price, CloseReason& closeReason, string symbol)
{
    profit = 0;
    type = -1;
    price = 0;
    int lastOrder = 0;
    datetime lastCloseTime = 0;

    // Loop through all closed orders
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         {
              // Check if the order is from the specified magic number
              if(OrderMagicNumber() == Magic && symbol == OrderSymbol())
              {
                    if(OrderCloseTime() > lastCloseTime)
                    {
                         lastCloseTime = OrderCloseTime();
                         lastOrder = OrderTicket();
                         profit = OrderProfit();
                         type = OrderType();
                         price = OrderClosePrice();
                         time = lastCloseTime;
                         order = lastOrder;
                          // Get the close reason
                          if(OrderProfit() < 0 && MathAbs(OrderClosePrice() - OrderStopLoss()) < Point)
                          {
                               closeReason = StopLoss;
                          }
                          else if(OrderProfit() > 0 && MathAbs(OrderClosePrice() - OrderTakeProfit()) < Point)
                          {
                               closeReason = TakeProfit;
                          }
                          else
                          {
                               closeReason = Manual;
                          }
                    }
              }
         }
    }

    return lastOrder!=0; // Return false if we didn't find the order
}

// Get the sum of profits of last consecutive sequence of orders that starts from loss till all loss is recovered
// 
double GetSumProfitSinceLoss(int Magic, string symbol)
{
    double sumProfit = 0;
    bool foundLoss = false;

    // Loop through all closed orders
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
     if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
     {
       if(OrderMagicNumber() == Magic && symbol == OrderSymbol())
       {
         // Store order data for sorting
         int tempTickets[];
         datetime tempCloseTimes[];
         double tempProfits[];
         int tempCount = 0;
         
         // Collect all relevant orders first
         for(int j = OrdersHistoryTotal() - 1; j >= 0; j--)
         {
          if(OrderSelect(j, SELECT_BY_POS, MODE_HISTORY))
          {
              if(OrderMagicNumber() == Magic && symbol == OrderSymbol())
              {
               tempCount++;
               ArrayResize(tempTickets, tempCount);
               ArrayResize(tempCloseTimes, tempCount);
               ArrayResize(tempProfits, tempCount);
               
               tempTickets[tempCount-1] = OrderTicket();
               tempCloseTimes[tempCount-1] = OrderCloseTime();
               tempProfits[tempCount-1] = OrderProfit();
              }
          }
         }
         
         // Sort by close time (ascending)
         for(int k = 0; k < tempCount - 1; k++)
         {
          for(int l = k + 1; l < tempCount; l++)
          {
              if(tempCloseTimes[k] > tempCloseTimes[l])
              {
               // Swap close times
               datetime tempTime = tempCloseTimes[k];
               tempCloseTimes[k] = tempCloseTimes[l];
               tempCloseTimes[l] = tempTime;
               
               // Swap tickets
               int tempTicket = tempTickets[k];
               tempTickets[k] = tempTickets[l];
               tempTickets[l] = tempTicket;
               
               // Swap profits
               double tempProfit = tempProfits[k];
               tempProfits[k] = tempProfits[l];
               tempProfits[l] = tempProfit;
              }
          }
         }
         
         // Process sorted orders
         for(int m = 0; m < tempCount; m++)
         {
          // Check if the order is a loss
          if(!foundLoss && tempProfits[m] < 0)
              foundLoss = true;
          
          if(foundLoss)
              sumProfit += tempProfits[m];

          if(sumProfit >= 0) // look for next sequence of loss and profit < 0
          {
             sumProfit = 0;
             foundLoss = false;
          }
         }
         
         break; // Exit the outer loop since we've processed all orders
       }
     }
    }

    return sumProfit;
}