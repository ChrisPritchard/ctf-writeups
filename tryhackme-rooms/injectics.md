# Injectics

https://tryhackme.com/r/room/injectics, rated **Medium**. The name suggests that it includes various forms of Injection, e.g. SQLi, SSTI, os injection or whatever. The steps to solve the room are pretty basic, but there are some twists added that can trip people up if they don't sit back and think. In my case, at least a couple of steps ate up hours they shouldn't have :)

1. A scan reveals 22 and 80. On 80 is a website showing medals for some competition by country. In the source of the page is a reference to 'mail.log' which, when visited, states that if the users table is deleted or corrupted, new admin users will be created with fixed credentials.

2. There are two login pages, normal and admin. The normal page has javascript to remove SQLi terms, which indicates it is vulnerable to SQLi. A bit of experimentation will show that to bypass it the backing query needs to return at least one row - therefore sending a payload like `username=test&password='||(select 1)||'` will work, and log in to the dashboard as the `dev` user, but not as admin.

> while this injection will get you through, there are filters in place that prevent you reading the value of the password field for users directly, so you are limited to an auth bypass - specifically the filter removes OR, which means you can't specify the passw**OR**d column name. this also prevents use of inf**OR**mation_schema.

3. The dashboard allows you to update the medal count for a given country. The request for this is something like `rank=1&country=USA&gold=10&silver=10&bronze=10` - this is also vulnerable to SQLi, allowing you to affect the update call. However, the goal is to corrupt the users table, so we need to use a stacked query. Sending a payload like `...bronze=10;drop table users -- ` works, showing this update supports multiple (stacked) queries, and the user table is dropped. The site will helpfully then show a status message indicating the service mentioned in mail.log is fixing the site.

4. Once the site is back, you can then log into the admin portal with the credentials from mail.log. This provides the first flag. The admin portal is just the normal dashboard from non-admins, which starts with 'Welcome {firstname}', plus the ability to update your profile (i.e. your first name).

5. Submitting a payload for firstname like `{{7*'7'}}` will result in `Welcome 49`, indicating this is SSTI. Some further experimentation will reveal the engine to be Twig, and using some common payloads for that will show that Twig is running in 'sandbox' mode and so most SSTI payloads for Twig will not work. However, if you set fname to `{{['id',""]|sort('system')}}` you will get an error that says the php function `system` is disabled - this indicates that this payload will work, and you just need the right php function. `{{['id',""]|sort('passthru')}}` works, given you RCE, and with this you can find the hidden flag file name under /flags (e.g. `ls flags`) for the final flag.

> for an interesting writeup of this in a similar situation (but one where system wasn't blocked), see https://www.hackthebox.com/blog/business-ctf-2022-phishtale-writeup

With the RCE a shell can be obtained on the machine to read the source code and work out how various things were blocked or stopped. It also provides the credentials to the database, that can be accessed via /phpmyadmin (possibly an oversight, as the password is fairly simple but not part of common wordlists surprisingly as far as I could see):

functions.php (used for the basic login):

```php
$email = str_ireplace([ "AND", "OR", "UNION"], "", $email);
$password = str_ireplace(["AND", "OR", "UNION"], "", $password);
$sql = "SELECT * FROM users WHERE email='$email' AND password='$password'";
if ($result->num_rows > 0) { ...
```

edit_leaderboard.php:

```php
// List of common SQL commands to remove, except for DROP and UPDATE
    $sqlCommands = [
        'SELECT', 'INSERT', 'DELETE', 'CREATE', 'ALTER', 'TRUNCATE',
        'MERGE', 'CALL', 'EXPLAIN', 'LOCK', 'UNLOCK', 'REPLACE',
        'HANDLER', 'LOAD', 'GRANT', 'REVOKE', 'SHOW', 'DESCRIBE',
        'USE', 'HELP', 'BEGIN', 'COMMIT', 'ROLLBACK', 'SAVEPOINT',
    'DECLARE', 'PREPARE', 'EXECUTE', 'DEALLOCATE', 'SLEEP', 'OR', 'AND', 'CURSOR'
    ];
...
$keywords = ['union', 'select', 'or', 'and', 'case', "SLEEP"];
foreach ($keywords as $keyword) {
        $input = str_ireplace($keyword, '', $input);
}
...
if ($conn->multi_query($sql) === TRUE) {
...
```

notably above, the multi_query allows stacking drop tables on the end.

dashboard.php (ssti section):

```php
$policy = new Twig\Sandbox\SecurityPolicy(
    ['if', 'for', 'block', 'filter', 'include'], // Allowed tags
    ['filter', 'map', 'reduce', 'sort', 'escape', 'length','join', 'raw', 'upper'], // Allowed filters
    [], // No allowed methods
    [], // No allowed properties
    [] // Allowed functions
);
$sandbox = new Twig\Extension\SandboxExtension($policy, true);
...
$template = $twig->createTemplate("Welcome, {{ name|raw }}!");
```
