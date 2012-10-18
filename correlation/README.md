#Correlation Indicators
There are 2 correlation indicators in this folder. The first is an oscillator and the second is a multi-time frame (MTF) tabular view. 

The oscillator presents a historical view of how the correlation changes over time for up to 8 user supplied symbols 
against the symbol of the current chart. The user can specify how man bars will be used to calculate the correlation
at each on the chart.

The MTF table presents the correlation for an arbitrary number of symbols against the chart symbol 
for the user selected time frames. The time frames can one or all of:
* M1
* M5
* M15
* M30
* H1
* H4
* D1
* W1
* MN1

For each selected time frame the user can specify the number of bars (the period) to be considered when calculating the
correlation.


#Disclaimer
Trading is inherently risky. If you use these indicators or any of the source code or libraries in this repository 
you do so acknowledging they are provided **AS-IS** and **WITH NO WARRANTY** of any kind. If you choose to use the
results of these indicators or supporting libraries in your trading or any other decision making processes you do so 
at **your own risk**. In downloading, cloning, or generally obtaining a copy of anything from within this repository 
you acknowledge the author, Michael O'Keeffe, is **NOT responsible** for any type of losses you incur as a result of 
using the:
* source code, 
* compiled or other binary products, or 
* any works derived from this source or binary code held in this repository.

#Output examples
A screen shot of the EURAUD with the oscillator.
![Oscillator](http://db.tt/MnuRmdWn)
A screen shot of the EURUSD with the correlation table.
![MTF Table](http://db.tt/dv7q1hjz)


#Dependencies
Both indicators are dependent on the following libraries:
* [ninety47_string](https://github.com/ninety47/mt4-libs/tree/master/string)
* [ninety47_common](https://github.com/ninety47/mt4-libs/tree/master/common)
* [ninety47_stats](https://github.com/ninety47/mt4-libs/tree/master/stats)

