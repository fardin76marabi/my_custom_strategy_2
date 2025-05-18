//+------------------------------------------------------------------+
//|                                                        ICT_1.mq5 |
//|                                                    Fardin Marabi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Fardin Marabi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+/*


/*
Strategy: a high is gotten by a second candel, but the second candel closes below the first high
if second low be gotten, we go to a sell to the first candel low

*/

#include<Trade/Trade.mqh>
CTrade trade;


//Global Variables
static input ENUM_TIMEFRAMES lowerTF=PERIOD_M1;
static input ENUM_TIMEFRAMES higherTF=PERIOD_H4;


input group "ORDERS SETTINGS"
input double Volume=0.01;
input double Stop_Loss_Coeff=1;
input double Take_Profit_Coeff=0.5;
input int Hours_Expire=10;
input double riskPerTrade=1;
input double RR=1.3;
input double shadowToBodyRel=1;
int barsTotal;
int signal_bar_total;


//global variables
double stop_loss;
double take_profit;

double market_bais=0;
double up_limit=0;
double down_limit=0;

double signal_controller=-1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   
   barsTotal=iBars(NULL,lowerTF);
   signal_bar_total=iBars(NULL,higherTF);
   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
//double Signal_Value;

void OnTick()
  {
//---

   
   int bars=iBars(NULL,lowerTF);
   int signal_bar=iBars(NULL,higherTF);
   
   
   
   if (barsTotal != bars){
      barsTotal=bars;
      
      int signal=Spotting_Patterns(lowerTF,higherTF);
      
      
      
      if((signal==2) && (signal_controller!=up_limit) ){  // && (signal_bar!= signal_bar_total)
      
         signal_bar_total=signal_bar;
         
         
         //in_validate_area(iClose(NULL,lowerTF,1));
   
         double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         
         
         //double poss_sl=up_limit;
         
         double poss_sl=stop_loss; 
         double poss_tp=down_limit;
         
         double distanceEntryFromSL=poss_sl-entry;
         
         
         
         if (RR_checker(entry,poss_sl,poss_tp)==1){
            // Check for new closed trades and update risk
            RiskManager.UpdateRisk();
            
            double vol=volume_calculator(distanceEntryFromSL*MathPow(10,_Digits));
            //double vol = CalculatePositionSize(distanceEntryFromSL*MathPow(10,_Digits));
            Print("***Vol is ", vol);
         
            signal_controller=up_limit;
            
            double sl=poss_sl;
            double tp=NormalizeDouble(entry-(RR*distanceEntryFromSL),_Digits);
            
            trade.Sell(vol,NULL,entry,sl,tp);
         }
         
         
      }
    
   }
   
   
  }
//+------------------------------------------------------------------+




int Spotting_Patterns(ENUM_TIMEFRAMES ltf,ENUM_TIMEFRAMES htf){

   //0 = No Signal
   //1 = Buy
   //2 = Sell
   
   market_bias_finder(ltf,htf);
   
   in_validate_area(iClose(NULL,lowerTF,1));// still in the trading zone
   
   if (market_bais==2){ //last market bias
      if (trend_ema(htf,10)==1) 
         if ( true){//trend_ema(ENUM_TIMEFRAMES tf,int period) price_in_trend(20,50,4,ltf)==1
            return 2;
         }
         
   }
   
   
   return 0;
}


void market_bias_finder(ENUM_TIMEFRAMES ltf,ENUM_TIMEFRAMES htf){
   if (iHigh(NULL,higherTF,1)>iHigh(NULL,higherTF,2)){
      if ((iHigh(NULL,higherTF,2)>iClose(NULL,higherTF,1) && iHigh(NULL,higherTF,2)>iOpen(NULL,higherTF,1)) ){
         if (iLow(NULL,higherTF,1)>iClose(NULL,lowerTF,1)){
            if (iLow(NULL,higherTF,1)>iLow(NULL,higherTF,2)){
              if (extra_conditions(lowerTF,higherTF)==2){
               stop_loss=iHigh(NULL,higherTF,1);//high 1
               take_profit=iLow(NULL,higherTF,2);
               
               market_bais=2;
               up_limit=iHigh(NULL,higherTF,1);
               down_limit=iLow(NULL,higherTF,2);
               //return 2; 
               }
            
            }
         }
      }
   }

   //return 0;
}



// Function to check for a bearish engulfing pattern
int CheckBearishEngulfing(ENUM_TIMEFRAMES ltf)
{
    // Get candle data for the current and previous candles
    double currentOpen = iOpen(NULL, ltf, 1);  // Current candle open price
    double currentClose = iClose(NULL, ltf, 1); // Current candle close price
    double previousOpen = iOpen(NULL, ltf, 2);  // Previous candle open price
    double previousClose = iClose(NULL, ltf, 2); // Previous candle close price

    // Check for a bearish engulfing pattern
    if (currentClose < currentOpen && // Current candle is bearish
        previousClose > previousOpen && // Previous candle is bullish
        currentOpen > previousClose && // Current candle opens above the previous close
        currentClose < previousOpen)   // Current candle closes below the previous open
    {
        // Bearish engulfing pattern detected
        stop_loss=iHigh(NULL,ltf,1);
        take_profit=down_limit;
        return 2;
    }

    // No pattern detected
    return 0;
}


void in_validate_area(double price){ // is price in a the bias recognized are or get out of that.
   if ((price>=up_limit) || (price<=down_limit) ){
      market_bais=0;
   }
   
   
}


int extra_conditions(ENUM_TIMEFRAMES ltf,ENUM_TIMEFRAMES htf){//adding some extra condition to pattern in htf (bias pattern)
   if (body_to_shadow(ltf,htf)==2){
      return 2;
   }
   
   return 0;
}

int compare_down_to_up_shadow(ENUM_TIMEFRAMES ltf,ENUM_TIMEFRAMES htf){ // not complete yet

   double body_high;
   double body_size;
   
   if(iClose(NULL,htf,1)>=iOpen(NULL,htf,1)){
      body_high=iClose(NULL,htf,1);
      body_size=iClose(NULL,htf,1)-iOpen(NULL,htf,1);
   }else{
      body_high=iOpen(NULL,htf,1);
      body_size=iOpen(NULL,htf,1)-iClose(NULL,htf,1);
   }
   
   if (body_size==0){
      return 2;
   }
   
   return 0;
}

int body_to_shadow(ENUM_TIMEFRAMES ltf,ENUM_TIMEFRAMES htf){ // check size of the size of the 1'th higherTF shadow with its body
   
   double body_high;
   double body_size;
   
   if(iClose(NULL,htf,1)>=iOpen(NULL,htf,1)){
      body_high=iClose(NULL,htf,1);
      body_size=iClose(NULL,htf,1)-iOpen(NULL,htf,1);
   }else{
      body_high=iOpen(NULL,htf,1);
      body_size=iOpen(NULL,htf,1)-iClose(NULL,htf,1);
   }
   
   if (body_size==0){
      return 2;
   }
   double shadow=iHigh(NULL,htf,1)-body_high;
   
   if ((shadow/body_size)>shadowToBodyRel){
      return 2;
   }
   
   return 0;
}


int RR_checker(double entry,double sl,double tp){

   Print("Entry POINT is ",entry);
   Print("possible sl is (defanite)",sl);
   Print("possible tp is ",tp);
   
   double entryToSl;
   double entryToTp;
   
   entryToSl=MathAbs(entry-sl);
   entryToTp=MathAbs(entry-tp);
   
   if (entryToSl==0){
      return 0;
   }
   
   if ((entryToTp/entryToSl)>RR){
      return 1;
   }
   else{
      return 0;
   }

      return 0;
}


int price_in_trend(int period,int numOfCandels,int crossesLimit,ENUM_TIMEFRAMES tf){ // check how many times two ema have cross: the more means market is in range not trend
   
   double myEMA2[];
   int emaDef2;
   
   emaDef2=iMA(_Symbol,tf,period,0,MODE_EMA,PRICE_CLOSE); //period=20
   ArraySetAsSeries(myEMA2,true);
   CopyBuffer(emaDef2,0,0,100,myEMA2); // last ema's for last 3 candel is in this array
   
   int numOfCrosses=0;
   
   double currentEMA;
   double one_before_EMA;
   
   double current;
   double one_before;
   
   for (int i=2;i<=numOfCandels;i++){
      current=iClose(NULL,tf,i);
      one_before=iClose(NULL,tf,i-1);
      
      currentEMA=myEMA2[i];
      one_before_EMA=myEMA2[i-1];
      
      if( (one_before>=one_before_EMA) && (current<=currentEMA) ){
         numOfCrosses+=1;
      }
      if( (one_before<=one_before_EMA) && (current>=currentEMA) ){
         numOfCrosses+=1;
      }
   }
   
   if (numOfCrosses<=crossesLimit){
      return 1;
   }
   
   return 0;
}


int trend_ema(ENUM_TIMEFRAMES tf,int period){ // calculate ema in a tf and a period then check price is above that or below that
   
   // ema 
   double myEMA2[];
   int emaDef2;
   emaDef2=iMA(_Symbol,tf,period,0,MODE_EMA,PRICE_CLOSE); //period=20
   ArraySetAsSeries(myEMA2,true);
   CopyBuffer(emaDef2,0,0,3,myEMA2); // last ema's for last 3 candel is in this array
   
   double myCurrentEMA=myEMA2[1];
   double lastCandel=iClose(NULL,tf,1);
   
   if (lastCandel>=myCurrentEMA){ // bullish Senario
      // if close price of last candel is above ema20
      return 1; 
   }
   if (lastCandel<myCurrentEMA){ // bearish Senario
      return 2;
   }
   return 0;
}


//+------------------------------------------------------------------+
//| Risk Management Class                                            |
//+------------------------------------------------------------------+
/*class CRiskManager
{
private:
    double      m_initialRiskPercent;  // Base risk percentage (e.g., 1%)
    double      m_currentRiskPercent;  // Current dynamic risk
    double      m_riskMultiplier;      // Multiplier after wins (e.g., 2)
    int         m_lastTradeResult;     // 1=win, -1=loss, 0=no trades yet
    
public:
    // Constructor
    CRiskManager(double initRisk=1.0, double multiplier=2.0) : 
        m_initialRiskPercent(initRisk),
        m_currentRiskPercent(initRisk),
        m_riskMultiplier(multiplier),
        m_lastTradeResult(0) {}
    
    // Update risk based on last trade result
    void UpdateRisk()
    {
        // Check last closed trade
        if(HistorySelect(0, TimeCurrent()))
        {
            int total = HistoryDealsTotal();
            if(total > 0)
            {
                ulong ticket = HistoryDealGetTicket(total-1);
                if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
                {
                    double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                    if(profit > 0) // Winning trade
                    {
                        m_lastTradeResult = 1;
                        m_currentRiskPercent *= m_riskMultiplier;
                        Print("Winning trade! Risk increased to: ", m_currentRiskPercent, "%");
                    }
                    else if(profit < 0) // Losing trade
                    {
                        m_lastTradeResult = -1;
                        m_currentRiskPercent = m_initialRiskPercent;
                        Print("Losing trade. Risk reset to: ", m_currentRiskPercent, "%");
                    }
                }
            }
        }
    }
    
    // Get current risk percentage
    double GetCurrentRisk() const { return m_currentRiskPercent; }
    
    // Get initial risk percentage
    double GetInitialRisk() const { return m_initialRiskPercent; }
    
    // Get last trade result
    int GetLastTradeResult() const { return m_lastTradeResult; }
};

*/




double volume_calculator(double stoploss)
{
   if(stoploss==0){
     return(0);
   }
   double riskPercent = RiskManager.GetCurrentRisk();
   
   //double usd_risk = riskPerTrade*0.01 * AccountInfoDouble(ACCOUNT_BALANCE); 
   double usd_risk = riskPercent*0.01 * AccountInfoDouble(ACCOUNT_BALANCE);
   
   
   Print("******** riskPercent ",riskPercent);
   
   if (riskPercent==-1){ // we are in negative cycle so we trade with lowest volume
      Print("******** negative ");
      return 0.01;
   }
   
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double profit=0; 
   bool check=OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,1,ask,ask+100*_Point,profit); // ?? type buy
   double point_value = profit*0.01; //?? zero!
   double lotsize = usd_risk/(stoploss*point_value);
   int volume_digits=int(MathAbs(MathLog10(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP))));    
   
   double final_lot=NormalizeDouble(lotsize,volume_digits);
   if (final_lot<=0.01){
      final_lot=0.01;
   }
   Print("Calculated Lot is ",final_lot);
   return final_lot;
  
}

//+------------------------------------------------------------------+
//| Calculate position size with dynamic risk                        |
//+------------------------------------------------------------------+
/*double CalculatePositionSize(double stopLossDistance)
{
    // Get account balance
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(balance <= 0) return 0;
    
    // Get current risk percentage
    double riskPercent = RiskManager.GetCurrentRisk();
    
    // Calculate risk amount in account currency
    double riskAmount = balance * riskPercent / 100.0;
    
    // Get tick value for the symbol
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if(tickValue <= 0) return 0;
    
    // Calculate position size
    double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double positionSize = riskAmount / (stopLossDistance * pointValue * tickValue);
    
    // Normalize and validate position size
    positionSize = NormalizeDouble(positionSize, 2);
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    positionSize = MathMax(minLot, MathMin(maxLot, positionSize));
    
    return positionSize;
}*/











//+------------------------------------------------------------------+
//| Enhanced Risk Management Class (5-trade evaluation)              |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Enhanced Risk Manager with Accurate Trade Tracking               |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
    double      m_initialRisk;       // Base risk percentage (e.g., 1%)
    double      m_currentRisk;       // Current risk percentage
    double      m_riskMultiplier;    // Risk multiplier for wins (e.g., 2.0)
    ulong       m_processedTickets[]; // Array of processed trade tickets
    int         m_tradeResults[];    // Circular buffer of trade results (1=win, -1=loss)
    int         m_bufferIndex;       // Current position in circular buffer
    int         m_tradesCount;       // Number of trades in buffer (up to 5)

public:
    // Constructor
    CRiskManager(double initRisk=1.0, double multiplier=2.0) :
        m_initialRisk(initRisk),
        m_currentRisk(initRisk),
        m_riskMultiplier(multiplier),
        m_bufferIndex(0),
        m_tradesCount(0)
    {
        ArrayResize(m_tradeResults, 5);
        ArrayInitialize(m_tradeResults, 0);
        ArrayResize(m_processedTickets, 0);
    }

    // Update trade history and adjust risk
    void UpdateRisk()
    {
        /*
        // Select trade history
        if(!HistorySelect(0, TimeCurrent())) 
        {
            Print("Failed to select trade history");
            return;
        }

        int totalDeals = HistoryDealsTotal();
        if(totalDeals <= 0) return;

        // Process new closed trades
        for(int i = totalDeals-1; i >= 0; i--)
        {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket == 0) continue;

            // Check if this is an exit deal and not processed yet
            if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT && 
               ArraySearch(m_processedTickets, ticket) == -1)
            {
                // Add to processed tickets
                int size = ArraySize(m_processedTickets);
                ArrayResize(m_processedTickets, size+1);
                m_processedTickets[size] = ticket;

                // Record trade result
                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                m_tradeResults[m_bufferIndex] = (profit > 0) ? 1 : -1;
                
                // Update circular buffer index
                m_bufferIndex = (m_bufferIndex + 1) % 5;
                if(m_tradesCount < 5) m_tradesCount++;
                
                Print("Processed trade #", ticket, " Result: ", (profit > 0) ? "Win" : "Loss");
            }
        }

        // Only evaluate when we have at least 5 trades
        if(m_tradesCount < 5) 
        {
            Print("Not enough trades for evaluation (", m_tradesCount, "/5)");
            return;
        }

        // Count wins and losses
        int wins = 0, losses = 0;
        for(int i = 0; i < 5; i++)
        {
            if(m_tradeResults[i] == 1) wins++;
            else if(m_tradeResults[i] == -1) losses++;
        }

        // Apply risk adjustment rules
        if(wins >= 3)
        {
            m_currentRisk = m_initialRisk * m_riskMultiplier;
            Print("3+ wins in last 5 trades. Risk increased to ", m_currentRisk, "%");
        }
        else if(losses >= 3)
        {
            m_currentRisk = m_initialRisk;
            Print("3+ losses in last 5 trades. Risk reset to ", m_currentRisk, "%");
        }*/
        
      int totalTrades=0;
      int totalWins=0;
      int index = 0;
      
      HistorySelect(0, TimeCurrent());
      
      Print("*************checking last 5 trades ");
      
      for(int i = HistoryDealsTotal()-1; i >= 0 && totalTrades < 2; i--)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
               totalTrades++;
               double p = HistoryDealGetDouble(ticket, DEAL_PROFIT);
               Print("Profit was ",p);
               if(p > 0){
                  totalWins++;
                }
         }
         
      }
      
      Print("totall Trades was ",totalTrades);
      Print("totall Wins was ",totalWins);
      if (totalWins>1){
         //m_currentRisk = m_initialRisk;
         m_currentRisk = m_currentRisk*m_riskMultiplier;
         Print("Good Cycle- Update risk to  ",m_currentRisk);
      }
      else{
         //m_currentRisk=-1;
         m_currentRisk=m_initialRisk;
         Print("Bad Cycle- Update risk to  ",m_currentRisk);
      }
      
    
    }

    // Helper function to search in array
    int ArraySearch(const ulong &array[], ulong value) const
    {
        for(int i = 0; i < ArraySize(array); i++)
            if(array[i] == value) return i;
        return -1;
    }

    // Get current risk percentage
    double GetCurrentRisk() const { return m_currentRisk; }

    // Reset risk manager
    void Reset()
    {
        m_currentRisk = m_initialRisk;
        m_bufferIndex = 0;
        m_tradesCount = 0;
        ArrayInitialize(m_tradeResults, 0);
        ArrayResize(m_processedTickets, 0);
        Print("Risk manager reset to initial state");
    }
};


    

// Global risk manager instance
CRiskManager RiskManager(2, 1.2); // 1% initial risk, 2x multiplier

