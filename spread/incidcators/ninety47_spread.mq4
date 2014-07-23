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

Copyright (C) 2014 Michael O'Keeffe (a.k.a. ninety47)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/gpl.txt>.

*/

//+------------------------------------------------------------------+
//|                                               ninety47_pread.mq4 |
//|                                         Copyright 2014, ninety47 |
//|                                              http://ninety47.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, ninety47"
#property link      "http://ninety47.com/trading"
#property strict
#property indicator_chart_window


// Enum for setting the displayed elements
enum SpreadInfoLevel {
   All = 0,       // Show all elements
   Average = 1,   // Only show spread and its average
   Range = 2      // Only show spread and its range
};

//-------------------------------------------------------------------
// Input Parmters
//-------------------------------------------------------------------
input bool show_symbol = true; // Show the chart symbol
input bool show_spread = true; // Show the spread
input SpreadInfoLevel spread_detail = All; // Amount info to display for the spread

input string symbol_FontFace = "Arial Black"; // Font family to use for the symbol label.
input color symbol_FontColor = clrSteelBlue;  // Colour to use for the symbol label
input int symbol_FontSize = 36; // Font size (in points) for the symbol label.

input string info_FontFace = "Arial"; // Font family to use for the info labels and values.
input color info_FontColor = clrBisque; // Colour to use for the info labels and values.
input int info_FontSize = 8; // Font size (in points) for the info labels and values.

input int xOffset = 20; // The X (horizontal) distance in pixels from the left margin.
input int yOffset = 20; // The Y (vertical) distance in pixels from the top of the page.
input int margin = 20;  // Distance between the symbols name and info elements



//-------------------------------------------------------------------
// Support Classes
//-------------------------------------------------------------------

/* Place hold class for Polymorphism.
 * To do:
 *    - Try using 'void' pointers.
 */
class Object {};


/* Basic event object. Passed be event sources to cosnumers.
 * Contructor takes a pointer to any Object and a code noting the
 * event.
 *
 * In its usage here the code value is unused.
 */
class EventObject : public Object {
private:
   Object *_src;
   int     _code;
public:
   EventObject(Object *src, int code=0) {
      _src = src;
      _code = code;
   }

   Object *getSource(void) {
      return(this._src);
   }
};


/* LinkedListItem is a container for link list elements.
 * It, like old Java, holds 'Objects' and elements must
 * cast appropriately once extracted before use.
 */
class LinkedListItem {
public:
   Object *value;
   LinkedListItem *prev;
   LinkedListItem *next;

   LinkedListItem(
      Object *val,
      LinkedListItem *previousItem, LinkedListItem *nextItem = NULL
   ) {
      this.value = val;
      this.prev = previousItem;
      this.next = nextItem;
   }
};


/* Iterators make working with contianers easier. Sadly the
 * containers provided with the new MQL4 libraries don't
 * support this style of iteration. So I've added these classes.
 *
 * Usage is simply:
 *
 * LinkedList myList();
 *
 *  // add objects the list
 * iter = myList.begin();
 * do {
 *    process( iter.value() );
 * } while(iter.next());
 *
 */
class LinkedListIterator {
private:
   LinkedListItem *current;
public:
   LinkedListIterator(LinkedListItem *first) {
      this.current = first;
   }

   bool next() {
      this.current = current.next;
      return(this.current != NULL);
   }

   Object *value() {
      Object *value = this.current.value;
      //this.current = this.current.next;
      return(value);
   }
};



/* Basic linked list ADT.
 * Only supports:
 *  - adding elements to its tail
 *  - forward iteration
 *  - memory safe destruction (unless held data types are unsafe).
 *
 * Used in the event handling classes.
 */
class LinkedList {
private:
   LinkedListItem *first;
   LinkedListItem *last;

public:
   LinkedList(Object *value=NULL) {
      if (value != NULL) {
         first = new LinkedListItem(value, NULL);
      } else {
         first = NULL;
      }
      last = NULL;
   }


   ~LinkedList(void) {
      LinkedListItem *curr = first,
                     *tmp;

      while (curr != NULL) {
         tmp = curr;
         curr = curr.next;
         delete tmp;
      }
   }


   void pushBack(Object *value) {
      LinkedListItem *item;
      if (first == NULL) {
         first = new LinkedListItem(value, NULL);
         last = NULL;
      } else if (last == NULL) {
         item = new LinkedListItem(value, first);
         first.next = item;
         last = item;
      } else {
         item = new LinkedListItem(value, last.next);
         last.next = item;
         last = item;
      }
   }


   LinkedListIterator *begin(void) {
      return (new LinkedListIterator(this.first));
   }
};



/* An abtract class, an class implementing this interface
 * can listen to an 'Updateable' object.
 * Essential this is the subject-observer pattern, where this class
 * (or its implementers) are the observers.
 */
class UpdateListener : public Object {
public:
   virtual void updateHandler(EventObject *evt) {};
};


/* An abstract class (although all methods have implementations.
 * It designed to be extended by a new class but provides support
 * for add listeners and trigger update events.
 *
 * In the subject-observer pattern this class is the subject.
 */
class Updateable : public Object {
protected:
   LinkedList _updateListners;

   void triggerUpdateEvent(EventObject *event) {
      LinkedListIterator *iter = this._updateListners.begin();
      UpdateListener *ul;
      do {
         ul = (UpdateListener*) iter.value();
         ul.updateHandler(event);
      } while (iter.next());
   }

public:
   void addUpdateListener(UpdateListener *listener) {
      this._updateListners.pushBack( (Object*) listener );
   }
};


/* The spread logger tracks the data for the spread. Ideally
 * this class should have a datastore to save/log spread values
 * into.
 */
class SpreadLogger : public Updateable {
private:
   double _lastSpread;
   double _min;
   double _max;
   double _mean;
   double _nobs;

public:
   SpreadLogger() {
      this._lastSpread = 0.0;
      this._min = 0.0;
      this._max = 0.0;
      this._mean = 0.0;
      this._nobs = 0.0;
   }

   // Core method that when called triggers the update event.
   void addTick(double spread) {
      if (this._nobs > 1) {
         this._min = fmin(this._min, spread);
         this._max = fmax(this._max, spread);
      } else {
         this._min = spread;
         this._max = spread;
      }
      //PrintFormat("[1/2] %s mean: %3.3f", __FUNCTION__, this._mean);
      this._mean = 1.0/(this._nobs + 1.0) * (spread + this._nobs * this._mean);
      //PrintFormat("[2/2] %s mean: %3.3f", __FUNCTION__, this._mean);
      this._nobs += 1.0;
      this._lastSpread = spread;
      this.triggerUpdateEvent(new EventObject(GetPointer(this)));
   }

   double lastSpread() {
      return(this._lastSpread);
   }

   double min() {
      return(this._min);
   }

   double max() {
      return(this._max);
   }

   double mean() {
      return(this._mean);
   }

   double numTicks() {
      return(this._nobs);
   }
};


/* Renders a view of the data held in the spread logger and listens
 * for changes to that data and updates itself to suite.
 */
class SpreadLoggerView : public UpdateListener {
private:
   string _objPrefix;
   string _font;
   int    _fontSize;
   color  _fontColor;
   SpreadInfoLevel _mode;
   int    _yOffsets[4];
   int    _xOffsets[2];
   int    _digits;
   SpreadLogger _logger;

   string _textObjSpreadId;
   string _textObjSpreadMinId;
   string _textObjSpreadMeanId;
   string _textObjSpreadMaxId;

   string _textObjSpreadValueId;
   string _textObjSpreadValueMinId;
   string _textObjSpreadValueMeanId;
   string _textObjSpreadValueMaxId;


   string _textSpread;
   string _textSpreadMin;
   string _textSpreadMax;
   string _textSpreadMean;


   void initRangeTextObjects() {
      this._textObjSpreadMinId = this._objPrefix + "spread_min";
      ObjectCreate(this._textObjSpreadMinId, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(
         this._textObjSpreadMinId, this._textSpreadMin,
         this._fontSize, this._font, this._fontColor
      );
      ObjectSet(this._textObjSpreadMinId, OBJPROP_CORNER, 0);
      ObjectSet(this._textObjSpreadMinId, OBJPROP_XDISTANCE, this._xOffsets[0]);
      ObjectSet(
         this._textObjSpreadMinId, OBJPROP_YDISTANCE, this._yOffsets[1]
      );

      this._textObjSpreadMaxId = this._objPrefix + "spread_max";
      ObjectCreate(this._textObjSpreadMaxId, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(
         this._textObjSpreadMaxId, this._textSpreadMax,
         this._fontSize, this._font, this._fontColor
      );
      ObjectSet(this._textObjSpreadMaxId, OBJPROP_CORNER, 0);
      ObjectSet(this._textObjSpreadMaxId, OBJPROP_XDISTANCE, this._xOffsets[0]);
      ObjectSet(
         this._textObjSpreadMaxId, OBJPROP_YDISTANCE, this._yOffsets[2]);
   }

   void initMeanTextObjects() {
      this._textObjSpreadMeanId = this._objPrefix + "spread_mean";
      ObjectCreate(this._textObjSpreadMeanId, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(
         this._textObjSpreadMeanId, this._textSpreadMean,
         this._fontSize, this._font, this._fontColor
      );
      ObjectSet(this._textObjSpreadMeanId, OBJPROP_CORNER, 0);
      ObjectSet(this._textObjSpreadMeanId, OBJPROP_XDISTANCE, this._xOffsets[0]);
      ObjectSet(
         this._textObjSpreadMeanId, OBJPROP_YDISTANCE, this._yOffsets[3]);
   }

   /*
   int _getWidthIfUsed(string id, int unusedValue=-1) {
      int value = unusedValue;
      if (id != NULL) {
         value = ObjectGet(id, OBJPROP_XSIZE);
      }
      return(value);
   }*/

   void initValueTextObjects() {
      // This is horrible hack but we need to know the widest label
      // to calculate the X Offset.
      int //widths[4],
          index;
      string ids[4],
             labelIds[4];

      /*widths[0] = this._getWidthIfUsed(this._textObjSpreadId);
      widths[1] = this._getWidthIfUsed(this._textObjSpreadMeanId);
      widths[2] = this._getWidthIfUsed(this._textObjSpreadMaxId);
      widths[3] = this._getWidthIfUsed(this._textObjSpreadMinId);
      this._xOffsets[1] = ArrayMaximum(widths) + 10;
      */

      // The hardcoded solution to resolve the BROKEN OBJPROP_XSIZE
      // It just returns zero!
      this._xOffsets[1] = 50 + 10;

      labelIds[0] =  this._textObjSpreadId;
      labelIds[1] =  this._textObjSpreadMeanId;
      labelIds[2] =  this._textObjSpreadMaxId;
      labelIds[3] =  this._textObjSpreadMinId;

      ids[0] = this._textObjSpreadValueId =
            this._objPrefix + "spread_value";
      ids[1] = this._textObjSpreadValueMeanId =
            this._objPrefix + "spread_value_mean";
      ids[2] = this._textObjSpreadValueMaxId =
            this._objPrefix + "spread_value_max";
      ids[3] = this._textObjSpreadValueMinId =
            this._objPrefix + "spread_value_min";

      for (index = 0; index < 4; index++) {
         //if (widths[index] < 0) {
         //   continue;
         //}
         if (labelIds[index] == NULL) {
            continue;
         }

         ObjectCreate(ids[index], OBJ_LABEL, 0, 0, 0);
         ObjectSetText(
            ids[index], "#init",
            this._fontSize, this._font, this._fontColor
         );
         ObjectSet(ids[index], OBJPROP_CORNER, 0);
         ObjectSet(
            ids[index], OBJPROP_XDISTANCE,
            this._xOffsets[0] + this._xOffsets[1]
         );
         ObjectSet(
            ids[index], OBJPROP_YDISTANCE,
            ObjectGet(labelIds[index], OBJPROP_YDISTANCE)
         );
      }
   }

public:
   SpreadLoggerView(
      string font, int fontSize, color clr,
      int xoffset, int yoffset, SpreadInfoLevel mode=All
   ) {
      int delta,
          marginTop = 3,
          marginRight = 5;
      this._digits = 1;
      this._font = font;
      this._fontSize = fontSize;
      this._fontColor = clr;

      // The "One and one third" magic constant turns points to pixels
      delta = (int) round((4.0/3.0) * this._fontSize);

      this._xOffsets[0] = xoffset;
      this._yOffsets[0] = yoffset;
      this._mode = mode;

      // Hardcoded but should make a paramter for the object.
      this._objPrefix = "n47_sv_";

      // With labels this in now redundant
      // but will keep because it might be handy later on.
      this._textSpread =     "Spread: ";
      this._textSpreadMin =  "Min: ";
      this._textSpreadMax =  "Max: ";
      this._textSpreadMean = "Average: ";

      // Create the item labels.
      this._textObjSpreadId = this._objPrefix + "spread";
      ObjectCreate(this._textObjSpreadId, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(
         this._textObjSpreadId, this._textSpread,
         this._fontSize, this._font, this._fontColor
      );
      ObjectSet(this._textObjSpreadId, OBJPROP_CORNER, 0);
      ObjectSet(this._textObjSpreadId, OBJPROP_XDISTANCE, this._xOffsets[0]);
      ObjectSet(this._textObjSpreadId, OBJPROP_YDISTANCE, this._yOffsets[0]);
      if (this._mode == Average) {
         this._textObjSpreadMaxId = NULL;
         this._textObjSpreadMinId = NULL;
         this._yOffsets[3] = this._yOffsets[0] + delta + marginTop;
         initMeanTextObjects();
      } else if (this._mode == Range) {
         this._textObjSpreadMeanId = NULL;
         this._yOffsets[1] = this._yOffsets[0] + delta + marginTop;
         this._yOffsets[2] = this._yOffsets[1] + delta + marginTop;
         initMeanTextObjects();
      } else { // All
         this._yOffsets[1] = this._yOffsets[0] + delta + marginTop;
         this._yOffsets[2] = this._yOffsets[1] + delta + marginTop;
         this._yOffsets[3] = this._yOffsets[2] + delta + marginTop;
         initRangeTextObjects();
         initMeanTextObjects();
      }

      // Must be called after label creation.
      initValueTextObjects();
   }


   ~SpreadLoggerView(void) {
      ObjectDelete(this._textObjSpreadId);
      ObjectDelete(this._textObjSpreadMinId);
      ObjectDelete(this._textObjSpreadMeanId);
      ObjectDelete(this._textObjSpreadMaxId);
   }


   void setMin(double min) {
      ObjectSetText(
         this._textObjSpreadValueMinId,
         DoubleToStr(min, this._digits),
         this._fontSize, this._font, this._fontColor
      );
   }

   void setMax(double max) {
      ObjectSetText(
         this._textObjSpreadValueMaxId,
         DoubleToStr(max, this._digits),
         this._fontSize, this._font, this._fontColor
      );
   }

   void setAverage(double average) {
      ObjectSetText(
         this._textObjSpreadValueMeanId,
         DoubleToStr(average, this._digits),
         this._fontSize, this._font, this._fontColor
      );
   }

   void setSpread(double spread) {
      ObjectSetText(
         this._textObjSpreadValueId,
         DoubleToStr(spread, this._digits),
         this._fontSize, this._font, this._fontColor
      );
   }


   void updateHandler(EventObject *evt) {
      SpreadLogger *sl = (SpreadLogger*) evt.getSource();
      this.setSpread(sl.lastSpread());
      this.setMin(sl.min());
      this.setMax(sl.max());
      this.setAverage(sl.mean());
   }
};


//-------------------------------------------------------------------
// Globals....
//-------------------------------------------------------------------
SpreadLogger *spreadLogger;
SpreadLoggerView *spreadLoggerView;



//-------------------------------------------------------------------
// Core MT4 functions..
//-------------------------------------------------------------------
void OnInit() {
   int delta = 0;

   if (show_symbol) {
      delta = (int) round( (4.0/3.0) * symbol_FontSize ); // Pixels to points hack
      ObjectCreate("n47_spread_symbol", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("n47_spread_symbol", _Symbol, symbol_FontSize, symbol_FontFace, symbol_FontColor);
      ObjectSet("n47_spread_symbol", OBJPROP_CORNER, 0);
      ObjectSet("n47_spread_symbol", OBJPROP_XDISTANCE, xOffset);
      ObjectSet("n47_spread_symbol", OBJPROP_YDISTANCE, yOffset);
   }

   // Setup the model
   spreadLogger = new SpreadLogger();

   // The view
   spreadLoggerView = new SpreadLoggerView(
      info_FontFace, info_FontSize, info_FontColor,
      xOffset, yOffset + delta + margin, spread_detail
   );

   // View listens for changes in the model
   spreadLogger.addUpdateListener(spreadLoggerView);
}


void OnDeinit(const int reason) {
   ObjectDelete("n47_spread_symbol");
   delete spreadLoggerView;
   delete spreadLogger;
}



int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
) {
   // Update the spreadlogger (model) with new data to update the display.
   spreadLogger.addTick(MarketInfo(_Symbol, MODE_SPREAD));
   return(0);
}


