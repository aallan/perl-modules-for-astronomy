@echo off
copy SOAP-Lite-COM-standalone.ctrl Lite.ctrl >nul
call perlctrl Lite.ctrl -f -c -i="CompanyName=soaplite.com;FileDescription=SOAP::Lite for Perl;ProductVersion=0.52;LegalCopyright=Copyright (C) 2000-2001 Paul Kulchenko"