@echo off
echo FSWIKI_HOME=%FSWIKI_HOME%
echo HTML�𐶐����܂��B
wiki2html.pl readme.wiki -css=default.css -output=sjis > readme.html
echo PDF�𐶐����܂��B
wiki2pdf.pl readme.wiki readme.pdf
