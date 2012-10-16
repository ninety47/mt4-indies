#Correlation Inicators
There are 2 correlation indicators in this folder. The first is an oscillator and the second is a multi-timeframe (MTF) tablular
view. 

The oscillator presents a historical view of how the correlation changes over time for upto 8 user supplied symbols 
against the symbol of the current chart. The user can sepcify how man bars will be used to calculate the correlation
at each on the chart.

The MTF table presents the correlation for an abitrary number of symbols against the chart symbol 
for the user selected time frames. The timeframes can one or all of:
* M1
* M5
* M15
* M30
* H1
* H4
* D1
* W1
* MN1

For each selected timeframe the user can sepific the number of bars (the period) to be considered when calculating the
correlation.


#Disclaimer
Trading is inherently risky. If you use these indicators or any of the source code or libraries in this repository 
you do so acknowledging they are provided **AS-IS** and **WITH NO WARRANTY** of any kind. If you chose to use the
results of these indicators or supporting libraries in your trading or any other decision making processes you do so 
at **your own risk**. In downloading, cloning, or generally obtaining a copy of anything from within this repository 
you acknowledge the author, Michael O'Keeffe, is **NOT responsilble** for any type of losses you incur as a result of 
using the:
* source code, 
* compiled or other binary products, or 
* any works derived from this source or binary code held in this repository.

#Output examples
A screenshot of the EURAUD with the oscillator.
![Oscillator](http://db.tt/MnuRmdWn)
A screenshot of the EURUSD with the correlation table.
![MTF Table](http://db.tt/dv7q1hjz)


#Dependencies
Both indicators are dependent on the following libraries:
* [ninety47_string](https://github.com/ninety47/mt4-libs/tree/master/string)
* [ninety47_common](https://github.com/ninety47/mt4-libs/tree/master/common)
* [ninety47_stats](https://github.com/ninety47/mt4-libs/tree/master/stats)

#To Do:
* ...