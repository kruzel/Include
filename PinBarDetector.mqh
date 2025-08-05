//+------------------------------------------------------------------+
//|                                             PinBarDetector.mqh   |
//|                Pin Bar Detection Function for MQL4               |
//+------------------------------------------------------------------+
// 
// // 
bool IsBullishPinBar(int shift, double ratio=3.0)
{
    double open = Open[shift];
    double close = Close[shift];
    double high  = High[shift];
    double low   = Low[shift];

    double body = MathAbs(close - open);
    double upper_wick = high - MathMax(open, close);
    double lower_wick = MathMin(open, close) - low;
    double candle_size = high - low;

    // Bullish Pin Bar: Lower wick at least 'ratio' times body, small upper wick
    if (lower_wick > body * ratio &&
        lower_wick > upper_wick * ratio &&
        body/candle_size < 0.3)
    {
        Print("Found bullish pin bar");
        return true;
    }
    return false;
}

bool IsBearishPinBar(int shift, double ratio=3.0)
{
    double open = Open[shift];
    double close = Close[shift];
    double high  = High[shift];
    double low   = Low[shift];

    double body = MathAbs(close - open);
    double upper_wick = high - MathMax(open, close);
    double lower_wick = MathMin(open, close) - low;
    double candle_size = high - low;

    // Bearish Pin Bar: Upper wick at least 'ratio' times body, small lower wick
    if (upper_wick > body * ratio &&
        upper_wick > lower_wick * ratio &&
        body/candle_size < 0.3)
    {
        Print("Found bearish pin bar");
        return true;
    }

    return false;
}