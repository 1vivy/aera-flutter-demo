//! The demo's Rust, shared by every target.
//!
//! - [`call`] and [`bytes`] are the **core**: pure work Dart calls
//!   synchronously. Natively through flutter_rust_bridge, on the web as
//!   `core.wasm`.
//! - [`DemoOps`] is the **ops** handler: run as root by the worker on WebUI
//!   and in-process on AERA and desktop.

mod fractal;

use serde::Deserialize;
use serde_json::{json, Value};
use surfaces_core::{OpError, Request};
use surfaces_ops::{builtin, input, Handler, JobCtx};

fn args<T: serde::de::DeserializeOwned>(request: &Request) -> Result<T, OpError> {
    serde_json::from_value(request.input.clone()).map_err(|e| OpError::new("input", e.to_string()))
}

/// The core's JSON calls.
pub fn call(request: &Request) -> Result<Value, OpError> {
    match request.op.as_str() {
        "greet" => {
            #[derive(Deserialize)]
            struct Greet {
                name: String,
            }
            let greet: Greet = args(request)?;
            Ok(json!(format!("Hello, {}! (from Rust)", greet.name)))
        }
        // SHA-256 of text.
        "sha256" => {
            let text = request.input.as_str().unwrap_or_default();
            Ok(json!(surfaces_core::hash::sha256_hex(text.as_bytes())))
        }
        // SHA-256 of bytes sent as unpadded base64url, for picked files.
        "sha256.b64" => {
            let text = request.input.as_str().unwrap_or_default();
            let bytes = surfaces_core::text::b64url_decode(text).map_err(|e| OpError::new("input", e))?;
            Ok(json!({
                "sha256": surfaces_core::hash::sha256_hex(&bytes),
                "size": bytes.len(),
                "sizeText": surfaces_core::text::format_bytes(bytes.len() as u64),
            }))
        }
        "build" => Ok(json!({
            "arch": std::env::consts::ARCH,
            "family": std::env::consts::FAMILY,
            "threads": threads(),
        })),
        other => Err(OpError::new("unknown-op", format!("The core has no {other}"))),
    }
}

fn threads() -> usize {
    #[cfg(not(target_family = "wasm"))]
    return std::thread::available_parallelism().map_or(1, |n| n.get());
    #[cfg(target_family = "wasm")]
    return 1;
}

/// The core's binary calls.
pub fn bytes(request: &Request) -> Result<Vec<u8>, OpError> {
    match request.op.as_str() {
        "mandelbrot" => Ok(fractal::render(&args(request)?)),
        other => Err(OpError::new("unknown-op", format!("The core has no {other}"))),
    }
}

#[cfg(target_family = "wasm")]
surfaces_core::export_wasm_core!(crate::call, crate::bytes);

/// The demo's ops. Unknown ops fall through to the built-ins (`sys.info`,
/// `fs.stat`, `fs.list`, `fs.hash`, `sys.wait`).
pub struct DemoOps;

#[derive(Deserialize)]
struct Primes {
    #[serde(default = "five_million")]
    below: u64,
}

fn five_million() -> u64 {
    5_000_000
}

impl Handler for DemoOps {
    fn call(&self, request: &Request, job: &JobCtx) -> Result<Value, OpError> {
        match request.op.as_str() {
            // CPU work with progress: counts primes by trial division, in
            // blocks, checking for cancel between them.
            "demo.primes" => {
                let args: Primes = input(request)?;
                let below = args.below.clamp(2, 50_000_000);
                let mut count = 0u64;
                let block = (below / 100).max(1000);
                let mut n = 2;
                while n < below {
                    job.check()?;
                    job.progress(n as f64 / below as f64, format!("{count} primes below {n}"));
                    let end = (n + block).min(below);
                    count += (n..end).filter(|&k| is_prime(k)).count() as u64;
                    n = end;
                }
                Ok(json!({ "below": below, "primes": count }))
            }
            _ => builtin::call(request, job),
        }
    }
}

fn is_prime(n: u64) -> bool {
    if n < 4 {
        return n >= 2;
    }
    if n % 2 == 0 || n % 3 == 0 {
        return false;
    }
    let mut i = 5;
    while i * i <= n {
        if n % i == 0 || n % (i + 2) == 0 {
            return false;
        }
        i += 6;
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn core_calls() {
        let greeting = call(&Request::new("greet", json!({"name": "Ada"}))).unwrap();
        assert_eq!(greeting, "Hello, Ada! (from Rust)");
        let hashed = call(&Request::new("sha256.b64", json!("aGk"))).unwrap();
        assert_eq!(hashed["size"], 2);
        assert_eq!(hashed["sha256"], surfaces_core::hash::sha256_hex(b"hi"));
        assert!(call(&Request::new("nope", Value::Null)).is_err());
    }

    #[test]
    fn origin_is_inside_the_set() {
        let pixels = bytes(&Request::new(
            "mandelbrot",
            json!({"width": 3, "height": 3, "x": 0.0, "y": 0.0, "scale": 0.01, "iterations": 100}),
        ))
        .unwrap();
        assert_eq!(&pixels[16..20], &[8, 12, 16, 255]);
        assert_eq!(pixels.len(), 36);
    }

    #[test]
    fn ops() {
        let primes = DemoOps.call(&Request::new("demo.primes", json!({"below": 100})), &JobCtx::none()).unwrap();
        assert_eq!(primes["primes"], 25);
        let info = DemoOps.call(&Request::new("sys.info", Value::Null), &JobCtx::none()).unwrap();
        assert!(info["os"].is_string());
    }
}
