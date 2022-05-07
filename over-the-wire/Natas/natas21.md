# Natas 21

To see the site:

1. Go to [http://natas21.natas.labs.overthewire.org](http://natas21.natas.labs.overthewire.org)
2. Log in with natas21, IFekPyrQXftziDEsUr3x21sYuahypdgJ

This site is co-located with [http://natas21-experimenter.natas.labs.overthewire.org](http://natas21-experimenter.natas.labs.overthewire.org), which is accessed with the same credentials.
The second site allows you to set any session value by specifying it in the query string, along with the `?submit=true` key. The form on this page is irrelevent.
Each site will generate their own session ids, but they share the same session location, so after setting the right keys using the experimenter form, you can return to the main page and change its session id to the experiment session id to inherit those values.

3. Go to [http://natas21-experimenter.natas.labs.overthewire.org](http://natas21-experimenter.natas.labs.overthewire.org) and login with the same credentials
4. Add the querystring `?debug=true&submit=true&admin=1` and load. The debug key should echo that admin=1 is now part of the session state.
5. Using browser dev tools, find the value of the PHPSESSID cookie.
6. Return to [http://natas21.natas.labs.overthewire.org](http://natas21.natas.labs.overthewire.org), edit the page with dev tools to set the session id to the value you collected, then reload.

The password to natas22 should be presented.