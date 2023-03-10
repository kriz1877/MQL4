//+------------------------------------------------------------------+
//|                                             CB-EA_ATREntries.mq4 |
//|                                   Copyright 2021, Chris Bakowski |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Chris Bakowski"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs
//--- Inputs
#include <CB-CustomFunctions.mqh>


string            EntryName            = "entry";
string            StopName             = "stop";
string            TargetName           = "target";

string            EntryText            = "EntryText";
string            StopText             = "StopText";
string            TargetText           = "TargetText";

string            StopDistanceText     =  "StopDistanceText";
string            CurrencyText         =  "RiskCurrency";

double            pipFilterx           =  1.0;
double            pipFilterInPrice     =  pipFilterx * PipValue();

input double      accountSize          =  46000;                                    // Account Equity
input double      riskPerTardePerc     =  0.125;                                      // Max Risk %
double            usdPerTrade          = (accountSize / 100) * riskPerTardePerc;
input double      RRR                  =  2.0;  //Risk : Reward Ratio
input bool        isLongTrade          =  true; // Long Trade?
input bool        halfSafe             =  true; // Max 1/2 Lot Size 0.5?

input int         indexCandle          =  1; //Index Candle
input bool        cancelNotifications  =  true; // Cancel Trade Notifications?
input bool        useATR               = false; // Use ATR Stops?
input bool        Use_Structure        = true; // Use Structure?
input int         Structure_Lookback   = 7;   // Structure Lookback
input int         ATR_Length           = 14;   // ATR Length
input double      ATR_Stop_Multiplier  = 1.5; // ATR Stop Mutiplier


double            Stop;
double            Entry;
double            Target;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

//+------------------------------------------------------------------+
//| Stop Calculations                                                |
//+------------------------------------------------------------------+

   double      previousHigh      =  High[indexCandle];
   double      previousLow       =  Low[indexCandle];
   double      spread            =  NormalizeDouble(Ask - Bid,_Digits);
   double      halfSpread        =  spread / 2;

               Entry             =  isLongTrade ? NormalizeDouble((previousHigh + pipFilterInPrice + halfSpread),_Digits) : NormalizeDouble((previousLow - pipFilterInPrice - halfSpread),_Digits);


   if(isLongTrade)
     {
      if(!useATR)
        {
         Stop = NormalizeDouble((previousLow  - pipFilterInPrice - halfSpread),_Digits);
        }
      else
        {
         if(!Use_Structure)
           {
            Stop = NormalizeDouble(Close[indexCandle] - (ATR_Stop_Multiplier * (NormalizeDouble(iATR(Symbol(),PERIOD_CURRENT,ATR_Length,indexCandle),_Digits))),_Digits);;
           }
         else
           {
            Stop = NormalizeDouble((Low[iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,Structure_Lookback,indexCandle)]) - (ATR_Stop_Multiplier * (NormalizeDouble(iATR(Symbol(),PERIOD_CURRENT,ATR_Length,indexCandle),_Digits))),_Digits);;
           }

        }
     }
   else
     {
      if(!useATR)
        {
         Stop = NormalizeDouble((previousHigh + pipFilterInPrice + halfSpread),_Digits);
        }
      else
        {
         if(!Use_Structure)
           {
            Stop = NormalizeDouble(Close[indexCandle] + (ATR_Stop_Multiplier * (NormalizeDouble(iATR(Symbol(),PERIOD_CURRENT,ATR_Length,indexCandle),_Digits))),_Digits);;
           }
         else
           {
            Stop = NormalizeDouble((High[iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,Structure_Lookback,indexCandle)]) + (ATR_Stop_Multiplier * (NormalizeDouble(iATR(Symbol(),PERIOD_CURRENT,ATR_Length,indexCandle),_Digits))),_Digits);;
           }
        }
     }


//+------------------------------------------------------------------+
//| Currency Loss                                                    |
//+------------------------------------------------------------------+


// double lotSize    = MarketInfo(NULL,MODE_LOTSIZE);
   double tickValue  = MarketInfo(NULL,MODE_TICKVALUE);

   if(Digits <= 3)
     {
      tickValue = tickValue / 100;
     }

   double maxLossDollar       = accountSize * (riskPerTardePerc / 100);
   double quoteRisk  = NormalizeDouble((maxLossDollar / tickValue),2);




   Target      =  NormalizeDouble((TargetPrice(isLongTrade,false,Entry,Stop,RRR,false)),_Digits);

   double      StopDistancePips  =  NormalizeDouble(GetDistanceInPips(Entry,Stop),2);

   double      lotSize           =  NormalizeDouble(GetLotSizeFromPricesScript(accountSize,riskPerTardePerc,Entry,Stop,false),2);

   double      halfLotSize       =  lotSize / 2;
   
   if(halfLotSize > 0.5)
     {
      halfLotSize = 0.5;
     }


   Print("Entry is: "+(string)Entry);
   Print("Stop is: "+(string)Stop);
   Print("Target is: "+(string)Target);
   Print("Lot Size is: "+(string)lotSize);
   Print("Half Lot Size is: "+(string)halfLotSize);

//+------------------------------------------------------------------+
//| objects                                                          |
//+------------------------------------------------------------------+


   Print(lotSize);


//---  entry
   ObjectDelete(EntryName);

   ObjectCreate(0,EntryName,OBJ_HLINE,0,Time[0],Entry);
   ObjectSet(EntryName,OBJPROP_COLOR,clrBlue);
   ObjectSet(EntryName,OBJPROP_WIDTH,2);
   ObjectSet(EntryName,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSet(EntryName,OBJPROP_SELECTABLE,false);
   ObjectSet(EntryName,OBJPROP_HIDDEN,false);
   ObjectSet(EntryName,OBJPROP_BACK,true);


//--- long stop
   ObjectDelete(StopName);

   ObjectCreate(0,StopName,OBJ_HLINE,0,Time[0],Stop);
   ObjectSet(StopName,OBJPROP_COLOR,clrRed);
   ObjectSet(StopName,OBJPROP_WIDTH,2);
   ObjectSet(StopName,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSet(StopName,OBJPROP_SELECTABLE,false);
   ObjectSet(StopName,OBJPROP_HIDDEN,false);
   ObjectSet(StopName,OBJPROP_BACK,true);


//--- long target
   ObjectDelete(TargetName);

   ObjectCreate(0,TargetName,OBJ_HLINE,0,Time[0],Target);
   ObjectSet(TargetName,OBJPROP_COLOR,clrGreen);
   ObjectSet(TargetName,OBJPROP_WIDTH,2);
   ObjectSet(TargetName,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSet(TargetName,OBJPROP_SELECTABLE,false);
   ObjectSet(TargetName,OBJPROP_HIDDEN,false);
   ObjectSet(TargetName,OBJPROP_BACK,true);



//+------------------------------------------------------------------+
//| text                                                             |
//+------------------------------------------------------------------+


   ObjectDelete(EntryText);
   ObjectCreate(0,EntryText,OBJ_TEXT,0,Time[0],Entry);
   ObjectSetText(EntryText,"                             " + (string)Entry,8,"Ariel",clrBlue);


   ObjectDelete(StopText);
   ObjectCreate(0,StopText,OBJ_TEXT,0,Time[0],Stop);
   ObjectSetText(StopText,"                              " + (string)Stop,8,"Ariel",clrRed);


   ObjectDelete(TargetText);
   ObjectCreate(0,TargetText,OBJ_TEXT,0,Time[0],Target);
   ObjectSetText(TargetText,"                            " + (string)Target,8,"Ariel",clrGreen);

   double pipTextPlacement = isLongTrade ? (Stop - Shift * 1) : (Stop + Shift * 1);

   ObjectDelete(StopDistanceText);
   ObjectCreate(0,StopDistanceText,OBJ_TEXT,0,Time[0],pipTextPlacement);
   ObjectSetText(StopDistanceText,"                                   "
                 + (string)StopDistancePips + " Pips | "
                 + (string)lotSize + " lots"+ " | "
                 + (string)halfLotSize,8,"Ariel",clrRed);




   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

ObjectDelete(EntryName);
ObjectDelete(StopName);
ObjectDelete(TargetName);

ObjectDelete(EntryText);
ObjectDelete(StopText);
ObjectDelete(TargetText);
ObjectDelete(StopDistanceText);

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   if(cancelNotifications)
     {

      if(isLongTrade)
        {
         bool beyondSL  =  Bid < Stop;
         bool entered   =  Ask > Entry;
         bool hitTarget =  Bid > Target;

         if(beyondSL)
            SendNotification(Symbol() + "Cancelled");
            Print("Cancelled");
         if(entered)
            SendNotification(Symbol() + "Entered");
            Print("Entered");
         if(hitTarget)
            SendNotification(Symbol() + "Hit Target");
            Print("Hit Target");
        }


      if(!isLongTrade)
        {
         bool beyondSL  =  Ask > Stop;
         bool entered   =  Bid < Entry;
         bool hitTarget =  Ask < Target;
         
         if(beyondSL)
            SendNotification(Symbol() + "Cancelled");
            Print("Cancelled");
         if(entered)
            SendNotification(Symbol() + "Entered");
            Print("Entered");
         if(hitTarget)
            SendNotification(Symbol() + "Hit Target");
            Print("Hit Target");
        }



     }//cancel
  }//onTick
//+------------------------------------------------------------------+







//+------------------------------------------------------------------+
//|GetLotSizeFromPrices                                              |
//+------------------------------------------------------------------+
double GetLotSizeFromPricesScript(double accEquity, double maxRiskPrc, double entryPrice, double stopLoss,  bool Debug)
  {
   double maxLossInPips = MathAbs(entryPrice - stopLoss) / PipValue();
   return GetLotSizeFromPipsScript(accEquity,maxRiskPrc,maxLossInPips,Debug);
  }//returns the optimal lot size using the distance between 2 prices
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| GetLotSizeFromPipsScript                                         |
//+------------------------------------------------------------------+
double GetLotSizeFromPipsScript(double accEquity, double maxRiskPrc, double maxLossInPips,  bool Debug)
  {

   double lotSize    = MarketInfo(NULL,MODE_LOTSIZE);
   double tickValue  = MarketInfo(NULL,MODE_TICKVALUE);

   if(Digits <= 3)
     {
      tickValue = tickValue / 100;
     }

   double maxLossDollar       = accEquity * (maxRiskPrc / 100);
   double maxLossInQuoteCurr  = maxLossDollar / tickValue;
   double optimalLotSize      = NormalizeDouble(maxLossInQuoteCurr / (maxLossInPips * PipValue()) / lotSize,2);

   if(Debug)
     {
      Print("");
      Print("Your stoploss in pips is: " + (string)maxLossInPips);
      Print("Your account equity is: " + (string)accEquity);
      Print("Your broker's lot sizing is: " + (string)lotSize);
      Print("Your exchange rate is: " + (string)tickValue);
      Print("Your risk per trade in USD is: " + (string)NormalizeDouble(maxLossDollar,2));
      Print("Your risk per trade in " + Symbol() + " is " + (string)NormalizeDouble(maxLossInQuoteCurr,2));
      Print("Minimum permitted amount of a lot is ",MarketInfo(Symbol(),MODE_MINLOT));
      Print("Your lot size should be " + (string)optimalLotSize);
     }
   return optimalLotSize;
  }//function returns the optimal lot size using the size of the stoploss and pipfilter
//+------------------------------------------------------------------+
