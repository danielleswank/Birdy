Birdy
=====

Best viewed in Chrome. 

Files can be found at https://github.com/danielleswank/Birdy

These instructions assume that you have node installed.   
Since you're a node shop I hope that is a safe assumption.  
If you don't have it installed, here are a few good installation instruction links:
https://github.com/joyent/node/wiki/Installation
https://gist.github.com/579814
 

1) Add this line to your hosts file "127.0.0.1 dev.freeflow.io"
2) Download Birdy from github and unpack https://github.com/danielleswank/Birdy
3) Open up your terminal and cd into the Birdy directory
4) Run "sudo npm install"
5) Run "sudo coffee app.coffee"
6) Go to http://dev.freeflow.io
7) Auth with Twitter
8) Type in keywords, @people, or lat,long. Press enter to search.


Things to know:
The stream is throttled, otherwise it was just scrolled too fast for popular terms.  
Searches are additive so OWS + BASEBALL probably won't have may results even though they will seperatly.  
You can toggle on and off search terms or remove them compleatly.
Try backspacing once you have a few terms in.
Lat,Long searches can't have a space after the comma. If they do they will be treated as a keyword (e.g. -36.34,85.23)


