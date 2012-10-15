//+------------------------------------------------------------------+
//|                                   ninety47_correlation_table.mq4 |
//|                                                 Michael O'Keeffe |
//|                                                 www.ninety47.com |
//+------------------------------------------------------------------+
#property copyright "Michael O\'Keeffe"
#property link      "www.ninety47.com"

#include <ninety47_string.mqh>
#include <ninety47_common.mqh>
#include <ninety47_stats.mqh>

#property indicator_chart_window


//--- input parameters
extern bool    show_m1 = false;
extern bool    show_m5 = true;
extern bool    show_m15 = false;
extern bool    show_m30 = true;
extern bool    show_h1 = true;
extern bool    show_h4 = true;
extern bool    show_d1 = true;
extern bool    show_w = false;
extern bool    show_mn = false;

//--- The number of bars for each timeframe 
//--- correlation calculation.
extern int     period_m1 = 90;
extern int     period_m5 = 90;
extern int     period_m15 = 90;
extern int     period_m30 = 90;
extern int     period_h1 = 90;
extern int     period_h4 = 90;
extern int     period_d1 = 90;
extern int     period_w = 12;
extern int     period_mn = 12;


extern string  symbols = "AUDUSD,EURUSD,GBPUSD,NZDUSD,USDCAD,USDCHF,USDJPY,EURJPY,AUDJPY";
extern string  symbols_sep = ",";

extern int     price_mode = PRICE_CLOSE;

extern double  level_neutral = 0.0;
extern double  level_weak = 0.2;
extern double  level_moderate = 0.5;
extern double  level_strong = 0.8;

extern color   text_colour = White;
extern color   text_colour_neutral = DarkGray;
extern color   text_colour_weak = DeepSkyBlue;
extern color   text_colour_moderate = DeepPink;
extern color   text_colour_strong = Red;
extern color   text_colour_error = Lime;

extern string  font = "Lucida Conosle";
extern int     font_size = 9;

extern int     table_margin = 15;
extern int     table_row_height = 20;
extern int     table_label_width = 60;
extern int     table_cell_width = 40;

   
//--- Globals
// symbols to determine correlation for.
string _symbols[];
int    numSymbols;

// Correlation calculation params
int    _period_tf[];
string _period_label[];
int    _period_corr[];
int    numPeriods;
datetime _last_bars[];


// precision used to display correlation values
int value_digits = 2;


color correlationToColour(double r) {
   double x = MathAbs(r);
   color result;   
   if (0 <= x && x < level_weak) result = text_colour_neutral;
   else if (level_weak <= x && x < level_moderate) result = text_colour_weak;
   else if (level_moderate <= x && x < level_strong) result = text_colour_moderate;
   else if (level_strong <= x && x <= 1) result = text_colour_strong;
   else result = text_colour_error; 
   return(result);  
}


//=============================================================================



int init()  {
   int index;
   int period;
   int symbol;
   int hWnd;
   int dims[2];
   string label;
   
   // Setup the symbols...
   StringSplit(symbols, symbols_sep, _symbols);
   index = StringArraySearch(_symbols, Symbol());   
   if ( index > -1 ) StringArrayDelete(_symbols, index);
   numSymbols = ArraySize(_symbols);
   if (numSymbols == 0) {
      Alert("Error: You need to supply some symbols or at least one that is different from the chart OR check separator is correct.");
      return(-1);
   }
   
   // Periods...   
   numPeriods = show_m1 + show_m5 + show_m15 + show_m30 + show_h1 + show_h4 + show_d1 + show_w + show_mn;
   ArrayResize(_period_tf, numPeriods);
   ArrayResize(_period_label, numPeriods);
   ArrayResize(_period_corr, numPeriods);
   
   // indexing: numSymbols * period_index + symbol_index
   ArrayResize(_last_bars, numSymbols * numPeriods);  
    
   period = 0;
   if (show_m1) {
      _period_tf[period] = PERIOD_M1;
      _period_label[period] = "M1";
      _period_corr[period] = period_m1;
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_M1, 2);
      }
      period++;
   }
   if (show_m5) {
      _period_tf[period] = PERIOD_M5;
      _period_label[period] = "M5";
      _period_corr[period] = period_m5;
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_M5, 2);
      }      
      period++;
   }
   if (show_m15) {
      _period_tf[period] = PERIOD_M15;
      _period_label[period] = "M15";
      _period_corr[period] = period_m15;      
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_M15, 2);
      }    
      period++;
   }
   if (show_m30) {
      _period_tf[period] = PERIOD_M30;
      _period_label[period] = "M30";
      _period_corr[period] = period_m30;
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_M30, 2);
      }             
      period++;
   }
   if (show_h1) {
      _period_tf[period] = PERIOD_H1;
      _period_label[period] = "H1";
      _period_corr[period] = period_h1;
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_H1, 2);
      }             
      period++;
   }
   if (show_h4) {
      _period_tf[period] = PERIOD_H4;
      _period_label[period] = "H4";
      _period_corr[period] = period_h4;      
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_H4, 2);
      }          
      period++;
   }
   if (show_d1) {
      _period_tf[period] = PERIOD_D1;
      _period_label[period] = "D1";
      _period_corr[period] = period_d1;
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_D1, 2);
      }      
      period++;
   }
   if (show_w) {
      _period_tf[period] = PERIOD_W1;
      _period_label[period] = "W";
      _period_corr[period] = period_w;
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_W1, 2);
      }      
      period++;
   }
   if (show_mn) {
      _period_tf[period] = PERIOD_MN1;
      _period_label[period] = "MN";
      _period_corr[period] = period_mn;
      for (symbol = 0; symbol  < numSymbols; symbol++) {         
         _last_bars[numSymbols*period + symbol] = iTime(_symbols[symbol], PERIOD_MN1, 2);
      }      
      period++;
   }   
   
   // Get screen dimensions
   getScreenDimensions(Symbol(), Period(), dims);

   
   
/*   int margin = 15;
   int cell_width = 40;
   int symbol_label_width = 60;   */
   
   int width = table_label_width + (numPeriods+1) * table_cell_width;
   int xoffset = dims[0] - width;
   
   // Create text objects   
   for (period = 0; period < numPeriods; period++) {
      label = "CORR_LABEL_PERIOD_" + _period_label[period];
      ObjectCreate(label, OBJ_LABEL, 0, 0, 0);
      ObjectSet(label, OBJPROP_XDISTANCE, xoffset + table_label_width + period * table_cell_width);
      ObjectSet(label, OBJPROP_YDISTANCE, table_margin);
      ObjectSetText(label, _period_label[period], font_size, font, text_colour);      
   }
   
   for (index = 0; index < numSymbols; index++) {
      label = "CORR_LABEL_SYMBOL_" + _symbols[index];
      ObjectCreate(label, OBJ_LABEL, 0, 0, 0);
      ObjectSet(label, OBJPROP_XDISTANCE, xoffset);
      ObjectSet(label, OBJPROP_YDISTANCE, table_margin + (index+1)*table_row_height);
      ObjectSetText(label, _symbols[index], font_size, font, text_colour);      
      
      for (period = 0; period < numPeriods; period++) {
         label = "CORR_VALUE_" + _symbols[index] + "_" + _period_label[period];
         ObjectCreate(label, OBJ_LABEL, 0, 0, 0);
         ObjectSet(label, OBJPROP_XDISTANCE, xoffset + table_label_width + period * table_cell_width);
         ObjectSet(label, OBJPROP_YDISTANCE, table_margin + (index+1) * table_row_height); 
         ObjectSetText(label, "-0.00", font_size, font, text_colour);               
      }
   }
     
   return(0);
}

int deinit() {
   int index, period;
   for (index = 0; index < numPeriods; index++) {
      ObjectDelete("CORR_LABEL_PERIOD_" + _period_label[index]);
   }   
   for (index = 0; index < numSymbols; index++) {
      ObjectDelete("CORR_LABEL_SYMBOL_" + _symbols[index]);
      for (period = 0; period < numPeriods; period++) {
         ObjectDelete("CORR_VALUE_" + _symbols[index] + "_" + _period_label[period]);                      
      }
   }
   return(0);
}

int start() {
   double x[], y[], r;
   int symbol, period, i,j;
   string label;
   datetime last_bar;   
   
   for (period = 0; period < numPeriods; period++) {          
      for (symbol = 0; symbol < numSymbols; symbol++) {
         last_bar = iTime(_symbols[symbol], _period_tf[period], 1);
         if ( iBars(_symbols[symbol], _period_tf[period]) < _period_corr[period] ) {
            ObjectSetText(label, "-");
            ObjectSet(label, OBJPROP_COLOR, correlationToColour(0.0));
         } else if ( _last_bars[numSymbols*period + symbol] < last_bar  ) {
            _last_bars[numSymbols*period + symbol] = last_bar;
            label = "CORR_VALUE_" + _symbols[symbol] + "_" + _period_label[period];
            ArrayResize(x, _period_corr[period]);
            ArrayResize(y, _period_corr[period]);
            for (i = 0; i < _period_corr[period]; i++) {
               x[i] = getPrice(Symbol(), price_mode, _period_tf[period], i);
               y[i] = getPrice(_symbols[symbol], price_mode, _period_tf[period], i);            
            }
            r = pearsons(_period_corr[period], x, y);
            ObjectSetText(label, DoubleToStr(r, value_digits));
            ObjectSet(label, OBJPROP_COLOR, correlationToColour(r));
         }
      }
      
   }
   return(0);
}


