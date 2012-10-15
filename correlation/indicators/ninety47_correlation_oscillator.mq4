/*
This library and source code are released under the GNU General Public
License v3. 

A copy of the license can be found in the my GitHub repository here
https://github.com/ninety47/mt4_indies/blob/master/gpl.txt

Trading is a risky business and in using this code you accept ALL 
responsibility for ensure it works as intended. Simply put I provide 
this code as-is with no warranty or guarantee that it works. I am
not liable for any losses you incur through bugs in the software
implemented in this library. 

All that said, feel free to chip me a couple of bones if you 
appreciate work I've done here and it helps you turn a profit.

----------------------------------------------------------------------

ninety47_string is a library of string handling functions for 
Metatrader 4 that are useful in indicators, expert advisors or 
general scripts.

Copyright (C) 2012  Michael O'Keeffe (a.k.a. ninety47)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.

*/

//+------------------------------------------------------------------+
//|                                         ninety47_correlation.mq4 |
//|                                                 www.ninety47.com |
//+------------------------------------------------------------------+
#property copyright "Michael O\'Keeffe"
#property link      "www.ninety47.com"

#include <ninety47_common.mqh>
#include <ninety47_stats.mqh>
#include <ninety47_string.mqh>

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_minimum -120.0
#property indicator_maximum 130.0
#property indicator_level1 100.0
#property indicator_level2 80.0
#property indicator_level3 0.0
#property indicator_level4 -80.0
#property indicator_level5 -100.0

#property indicator_color1 Crimson
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1

#property indicator_color2 SteelBlue
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1

#property indicator_color3 Chocolate
#property indicator_style3 STYLE_SOLID
#property indicator_width3 1

#property indicator_color4 MediumSeaGreen
#property indicator_style4 STYLE_SOLID
#property indicator_width4 1

#property indicator_color5 MediumVioletRed
#property indicator_style5 STYLE_SOLID
#property indicator_width5 1

#property indicator_color6 FireBrick
#property indicator_style6 STYLE_SOLID
#property indicator_width6 1

#property indicator_color7 DarkViolet
#property indicator_style7 STYLE_SOLID
#property indicator_width7 1

#property indicator_color8 LightSeaGreen
#property indicator_style8 STYLE_SOLID
#property indicator_width8 1

#define NO_DATA -99          
#define MAX_BUFFERS 8


//--- input parameters
extern int period = 50; 
extern string symbols = "EURUSD,GBPUSD,AUDUSD,S&P,DJ30,FT100,DAX30";
extern string symbols_sep = ",";

extern string NOTE_SYMMAX = "MAXIMUM NUMBER OF 8 SYMBOLS (excluding chart symbol)";
extern string PRICE_MODES = "CLOSE=0, OPEN=1, HIGH=2, LOW=3, MEDIAN=4, TYPICAL=5, WEIGHTED=6";

extern int price_mode = PRICE_CLOSE;
extern double scale_factor = 100.0;

extern int     pair1_draw = DRAW_LINE;
extern int     pair1_style = STYLE_SOLID;
extern color   pair1_color = Crimson;

extern int     pair2_draw = DRAW_LINE;
extern int     pair2_style = STYLE_SOLID;
extern color   pair2_color = SteelBlue;

extern int     pair3_draw = DRAW_LINE;
extern int     pair3_style = STYLE_SOLID;
extern color   pair3_color = Chocolate;

extern int     pair4_draw = DRAW_LINE;
extern int     pair4_style = STYLE_SOLID;
extern color   pair4_color = MediumSeaGreen;

extern int     pair5_draw = DRAW_LINE;
extern int     pair5_style = STYLE_SOLID;
extern color   pair5_color = MediumVioletRed;

extern int     pair6_draw = DRAW_LINE;
extern int     pair6_style = STYLE_SOLID;
extern color   pair6_color = FireBrick;

extern int     pair7_draw = DRAW_LINE;
extern int     pair7_style = STYLE_SOLID;
extern color   pair7_color = DarkViolet;

extern int     pair8_draw = DRAW_LINE;
extern int     pair8_style = STYLE_SOLID;
extern color   pair8_color = DodgerBlue;

extern bool    legend_show = true;
extern int     legend_margin = 15;
extern int     legend_row_height = 20;
extern int     legend_label_width = 60;
extern int     legend_cell_width = 40;
extern string  font = "Lucida Conosle";
extern int     font_size = 10;


//--- buffers -----------------------------------------------------------------
// Can't see any other way of doing this ... an array of pointers would be nice.
// Indicator buffers
double buffer_pair1[], buffer_pair2[], buffer_pair3[],   
       buffer_pair4[], buffer_pair5[], buffer_pair6[],
       buffer_pair7[], buffer_pair8[];

// Calculation buffers (exchange memory use for computational speed up).
double data1[], data2[], data3[],   
       data4[], data5[], data6[],
       data7[], data8[];

// The list of symbols to be used (max 8) extrated from sybmols_str
string _symbols[];
int    numSymbols;


//--- Buffer handling functions -----------------------------------------------
// The follow functions encapsulate the sets of data buffers that are used
// for display and caculation.


void initBuffers(int numBuffers) {   
   IndicatorBuffers(numBuffers);
   
   // Indicator drawing buffers.
   SetIndexBuffer(0, buffer_pair1); 
   SetIndexStyle(0, pair1_draw, pair1_style, 1, pair1_color);
   if (1 <= numBuffers) SetIndexLabel(0, _symbols[0]);     
   
   SetIndexBuffer(1, buffer_pair2);
   SetIndexStyle(1, pair2_draw, pair2_style, 1, pair2_color);   
   if (2 <= numBuffers) SetIndexLabel(1, _symbols[1]);   
   
   SetIndexBuffer(2, buffer_pair3);
   SetIndexStyle(2, pair3_draw, pair3_style, 1, pair3_color);
   if (3 <= numBuffers) SetIndexLabel(2, _symbols[2]);
   
   SetIndexBuffer(3, buffer_pair4);
   SetIndexStyle(3, pair4_draw, pair4_style, 1, pair4_color);
   if (4 <= numBuffers) SetIndexLabel(3, _symbols[3]);   
   
   SetIndexBuffer(4, buffer_pair5);
   SetIndexStyle(4, pair5_draw, pair5_style, 1, pair5_color);
   if (5 <= numBuffers) SetIndexLabel(4, _symbols[4]);   
   
   SetIndexBuffer(5, buffer_pair6);
   SetIndexStyle(5, pair6_draw, pair6_style, 1, pair6_color);
   if (6 <= numBuffers) SetIndexLabel(5, _symbols[5]);
   
   SetIndexBuffer(6, buffer_pair7);
   SetIndexStyle(6, pair7_draw, pair7_style, 1, pair7_color);
   if (numBuffers >= 7) SetIndexLabel(6, _symbols[6]);
      
   SetIndexBuffer(7, buffer_pair8);
   SetIndexStyle(7, pair8_draw, pair8_style, 1, pair8_color);
   if (numBuffers == 8) SetIndexLabel(7, _symbols[7]);

   // Calculation buffers
   ArrayResize(data1, period); 
   ArrayResize(data2, period); 
   ArrayResize(data3, period); 
   ArrayResize(data4, period); 
   ArrayResize(data5, period); 
   ArrayResize(data6, period); 
   ArrayResize(data7, period); 
   ArrayResize(data8, period); 
}


void setIndicatorBuffers(int index, double x[]) {  
   // swtich statement to get around the lack of dynamic 
   // buffer buffer counts and a bit efficiency of 
   // computation e.g. do them all at once.
   switch(numSymbols) {
   case 1: 
      buffer_pair1[index] = scale_factor * pearsons(period, x, data1); 
      buffer_pair2[index] = NO_DATA * scale_factor;
      buffer_pair3[index] = NO_DATA * scale_factor;
      buffer_pair4[index] = NO_DATA * scale_factor;
      buffer_pair5[index] = NO_DATA * scale_factor;
      buffer_pair6[index] = NO_DATA * scale_factor;
      buffer_pair7[index] = NO_DATA * scale_factor;
      buffer_pair8[index] = NO_DATA * scale_factor;
      break;
   case 2: 
      buffer_pair1[index] = scale_factor * pearsons(period, x, data1); 
      buffer_pair2[index] = scale_factor * pearsons(period, x, data2);
      buffer_pair3[index] = NO_DATA * scale_factor;
      buffer_pair4[index] = NO_DATA * scale_factor;
      buffer_pair5[index] = NO_DATA * scale_factor;
      buffer_pair6[index] = NO_DATA * scale_factor;
      buffer_pair7[index] = NO_DATA * scale_factor;
      buffer_pair8[index] = NO_DATA * scale_factor;
      break;
   case 3: 
      buffer_pair1[index] = scale_factor * pearsons(period, x, data1); 
      buffer_pair2[index] = scale_factor * pearsons(period, x, data2);
      buffer_pair3[index] = scale_factor * pearsons(period, x, data3); 
      buffer_pair4[index] = NO_DATA * scale_factor;
      buffer_pair5[index] = NO_DATA * scale_factor;
      buffer_pair6[index] = NO_DATA * scale_factor;
      buffer_pair7[index] = NO_DATA * scale_factor;
      buffer_pair8[index] = NO_DATA * scale_factor;
      break;
   case 4: 
      buffer_pair1[index] = scale_factor * pearsons(period, x, data1); 
      buffer_pair2[index] = scale_factor * pearsons(period, x, data2);
      buffer_pair3[index] = scale_factor * pearsons(period, x, data3); 
      buffer_pair4[index] = scale_factor * pearsons(period, x, data4); 
      buffer_pair5[index] = NO_DATA * scale_factor;
      buffer_pair6[index] = NO_DATA * scale_factor;
      buffer_pair7[index] = NO_DATA * scale_factor;
      buffer_pair8[index] = NO_DATA * scale_factor;
      break;
   case 5: 
      buffer_pair1[index] = scale_factor * pearsons(period, x, data1); 
      buffer_pair2[index] = scale_factor * pearsons(period, x, data2);
      buffer_pair3[index] = scale_factor * pearsons(period, x, data3); 
      buffer_pair4[index] = scale_factor * pearsons(period, x, data4); 
      buffer_pair5[index] = scale_factor * pearsons(period, x, data5); 
      buffer_pair6[index] = NO_DATA * scale_factor;
      buffer_pair7[index] = NO_DATA * scale_factor;
      buffer_pair8[index] = NO_DATA * scale_factor;
      break;
   case 6: 
      buffer_pair1[index] = scale_factor * pearsons(period, x, data1); 
      buffer_pair2[index] = scale_factor * pearsons(period, x, data2);
      buffer_pair3[index] = scale_factor * pearsons(period, x, data3); 
      buffer_pair4[index] = scale_factor * pearsons(period, x, data4); 
      buffer_pair5[index] = scale_factor * pearsons(period, x, data5); 
      buffer_pair6[index] = scale_factor * pearsons(period, x, data6); 
      buffer_pair7[index] = NO_DATA * scale_factor;
      buffer_pair8[index] = NO_DATA * scale_factor;
      break;   
   case 7: 
      buffer_pair1[index] = scale_factor * pearsons(period, x, data1); 
      buffer_pair2[index] = scale_factor * pearsons(period, x, data2);
      buffer_pair3[index] = scale_factor * pearsons(period, x, data3); 
      buffer_pair4[index] = scale_factor * pearsons(period, x, data4); 
      buffer_pair5[index] = scale_factor * pearsons(period, x, data5); 
      buffer_pair6[index] = scale_factor * pearsons(period, x, data6); 
      buffer_pair7[index] = scale_factor * pearsons(period, x, data7);       
      buffer_pair8[index] = NO_DATA * scale_factor;
      break;   
   case 8:
   default:
      buffer_pair1[index] = scale_factor * pearsons(period, x, data1); 
      buffer_pair2[index] = scale_factor * pearsons(period, x, data2);
      buffer_pair3[index] = scale_factor * pearsons(period, x, data3); 
      buffer_pair4[index] = scale_factor * pearsons(period, x, data4); 
      buffer_pair5[index] = scale_factor * pearsons(period, x, data5); 
      buffer_pair6[index] = scale_factor * pearsons(period, x, data6); 
      buffer_pair7[index] = scale_factor * pearsons(period, x, data7);       
      buffer_pair8[index] = scale_factor * pearsons(period, x, data8);
      break;   
   }
}


void setDataBuffer(int bufferId, int index, int shift) {
   double price = getPrice(_symbols[bufferId], price_mode, Period(), shift);   
   switch(bufferId) {
   case 0: data1[index] = price; break;
   case 1: data2[index] = price; break;
   case 2: data3[index] = price; break;
   case 3: data4[index] = price; break;
   case 4: data5[index] = price; break;
   case 5: data6[index] = price; break;   
   case 6: data7[index] = price; break;   
   case 7: data8[index] = price; break;   
   }
}

color getBufferColor(int bufferId) {
   color value;
   switch(bufferId) {
   case 0: value = pair1_color; break;
   case 1: value = pair2_color; break;
   case 2: value = pair3_color; break;
   case 3: value = pair4_color; break;
   case 4: value = pair5_color; break;
   case 5: value = pair6_color; break;
   case 6: value = pair7_color; break;
   case 7: value = pair8_color; break;
   default: value = White; break;
   }
   return(value);
}

double getLastBufferValue(int bufferId) {
   double value;
   switch(bufferId) {
   case 0: value = buffer_pair1[1]; break;
   case 1: value = buffer_pair2[1]; break;
   case 2: value = buffer_pair3[1]; break;
   case 3: value = buffer_pair4[1]; break;
   case 4: value = buffer_pair5[1]; break;
   case 5: value = buffer_pair6[1]; break;
   case 6: value = buffer_pair7[1]; break;
   case 7: value = buffer_pair8[1]; break;
   default: value = White; break;
   }
   return(value);
}



//--- core functions ----------------------------------------------------------

int init() {
   int index;   
   int dims[2];   
   int width;
   int xoffset;
   string label;
   
   // Setup the symbols...
   StringSplit(symbols, symbols_sep, _symbols);
   index = StringArraySearch(_symbols, Symbol());
   if ( index >= 0 ) StringArrayDelete(_symbols, index);
   numSymbols = ArraySize(_symbols);
   
   // Need to show have at least 1 symbols
   if (numSymbols == 0) {
      Alert("Error: You need to supply some symbols or at least one that is different from the chart OR check separator is correct.");
      return(0);
   }
   
   // We can only handle 8 symbols (due buffer limitations) 
   // Plus more than 8 would just be unreadable on the chart.
   if (numSymbols > MAX_BUFFERS) {
      Alert("Error: Too many symbols request. Maximum number of symbols in 8 (in addition to the chart)");
      return(0);
   }
   symbols = ArrayToString(_symbols, symbols_sep);
   
   
   // Setup the buffers
   initBuffers(numSymbols);
   IndicatorShortName("Corr(" + period  + "): " + Symbol() + " Vs. [" + symbols + "]: ");

   // Create the legend objects   
   if (legend_show) {     
      getScreenDimensions(Symbol(), Period(), dims);      
      width = legend_label_width + legend_cell_width * 2 + 3*legend_margin;
      
      xoffset = dims[0] - width;
      for (index = 0; index < numSymbols; index++) {
         label = "LEGEND_LABEL_" + _symbols[index];
         ObjectCreate(label, OBJ_LABEL, 0, 0, 0);
         ObjectSet(label, OBJPROP_XDISTANCE, xoffset);
         ObjectSet(label, OBJPROP_YDISTANCE, index * legend_row_height + legend_margin);
         ObjectSetText(label, _symbols[index], font_size, font, getBufferColor(index));

         label = "LEGEND_VALUE_" + _symbols[index];
         ObjectCreate(label, OBJ_LABEL, 0, 0, 0);
         ObjectSet(label, OBJPROP_XDISTANCE, xoffset + legend_label_width + legend_margin);
         ObjectSet(label, OBJPROP_YDISTANCE, index * legend_row_height + legend_margin);
         ObjectSetText(label, " 0.000", font_size, font, getBufferColor(index));
      }
   }
     
   return(0);
}

int deinit() {   
   int index;
   // Clean up the created objects..
   if (legend_show) {
      for (index = 0; index < numSymbols; index++) {
         ObjectDelete("LEGEND_LABEL_" + _symbols[index]);
         ObjectDelete("LEGEND_VALUE_" + _symbols[index]);
      }
   }
   return(0);
}


int start() {

   int counted_bars = IndicatorCounted();   
   int index, pair, bar;
   double x[];             // Hope MQL5 has a new operator :)
   ArrayResize(x, period); // Shoul have look!

   // Don't bother if we don't have enough bars
   if (Bars <= period) return(0);
   
   // Init the buffers.
   if (counted_bars < 1) {
      for (index = 1; index <= period; index++) {
         buffer_pair1[Bars - index] = 0.0;
         buffer_pair2[Bars - index] = 0.0;
         buffer_pair3[Bars - index] = 0.0;
         buffer_pair4[Bars - index] = 0.0;
         buffer_pair5[Bars - index] = 0.0;
         buffer_pair6[Bars - index] = 0.0;
         buffer_pair7[Bars - index] = 0.0;
         buffer_pair8[Bars - index] = 0.0;
      }   
   }
   bar = Bars - counted_bars - 1;
   
   // Calculate the indicator.
   while (bar >= 0) {      
      for (index = 0; index < period; index++) {
         x[index] = getPrice(Symbol(), price_mode, Period(), bar + index);         
         for (pair = 0; pair < numSymbols; pair++) {            
            setDataBuffer(pair, index, bar + index);
         }
      }
      setIndicatorBuffers(bar, x);
      bar--;
   }
   
   // Update legend values
   for (index = 0; index < numSymbols; index++) {
      ObjectSetText("LEGEND_VALUE_" + _symbols[index], DoubleToStr( getLastBufferValue(index),3));
   }
   

   return(0);
}

