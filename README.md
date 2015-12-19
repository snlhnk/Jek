# AtenaWriter

make a pdf of Hagaki postcard addressing in vertical (tategaki) style from a CSV file.

## requirement

* gems
  - sinatra
  - sinatra-contrib
  - prawn
  - rack-test
  - minitest
  - minitest-doc_reporter

* font
  - TKaisho-GT01.ttf from T-Font project
    + T-Font (C) Sakamura-Koshizuka Laboratory, The University of Tokyo
    + http://www.sakamura-lab.org/FONT/

## usage

The source csv must have items below in this sequence:
1. furigana (pronunciation)
2. name in kanji
3. title (-Sama etc)
4. zip-code
5. address 1
6. address 2
7. family 1
8. title for family 1
9. family 2
10. title for family 2

You upload a source csv file, then download a pdf file. 
