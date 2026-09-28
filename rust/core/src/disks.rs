//! An app-level backend switch, the way an app like CBM picks between
//! fastboot and dd: one trait for the job, one implementation per way of
//! doing it, and the ops handler picks the first one this host can use.
//! Dart sees a single op (`demo.disks`) plus `demo.disks.backends` to show
//! which ways exist here; surfaces itself knows nothing about disks.
//!
//! Here the job is "list the block devices":
//! - [`ByName`] reads `/dev/block/by-name`, the on-device way (root on
//!   Android: the WebUI worker, or AERA).
//! - [`SysBlock`] reads `/sys/block`, which any Linux has (desktop, the AERA
//!   simulator, a phone without by-name links).

use serde_json::{json, Value};
use surfaces_core::OpError;

/// One way to do the job. Add an implementation to add a backend.
pub trait DiskBackend: Sync {
    fn name(&self) -> &'static str;
    /// Whether this host can use it, checked cheaply at call time.
    fn available(&self) -> bool;
    fn list(&self) -> Result<Vec<Value>, OpError>;
}

pub struct ByName;
pub struct SysBlock;

/// In order of preference.
pub static BACKENDS: &[&dyn DiskBackend] = &[&ByName, &SysBlock];

fn entries(dir: &str) -> Result<Vec<String>, OpError> {
    let mut names: Vec<String> = std::fs::read_dir(dir)
        .map_err(OpError::io)?
        .filter_map(|e| e.ok())
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .collect();
    names.sort();
    Ok(names)
}

impl DiskBackend for ByName {
    fn name(&self) -> &'static str {
        "by-name"
    }
    fn available(&self) -> bool {
        std::fs::read_dir("/dev/block/by-name").is_ok()
    }
    fn list(&self) -> Result<Vec<Value>, OpError> {
        Ok(entries("/dev/block/by-name")?
            .into_iter()
            .map(|name| {
                let target = std::fs::read_link(format!("/dev/block/by-name/{name}"))
                    .map(|t| t.to_string_lossy().into_owned())
                    .unwrap_or_default();
                json!({ "name": name, "device": target })
            })
            .collect())
    }
}

impl DiskBackend for SysBlock {
    fn name(&self) -> &'static str {
        "sysfs"
    }
    fn available(&self) -> bool {
        std::fs::read_dir("/sys/block").is_ok()
    }
    fn list(&self) -> Result<Vec<Value>, OpError> {
        Ok(entries("/sys/block")?
            .into_iter()
            .map(|name| {
                // Size is in 512-byte sectors.
                let sectors: u64 = std::fs::read_to_string(format!("/sys/block/{name}/size"))
                    .ok()
                    .and_then(|s| s.trim().parse().ok())
                    .unwrap_or(0);
                json!({ "name": name, "size": surfaces_core::text::format_bytes(sectors * 512) })
            })
            .collect())
    }
}

/// Which backends exist and which this host can use.
pub fn backends() -> Value {
    json!(BACKENDS
        .iter()
        .map(|b| json!({ "name": b.name(), "available": b.available() }))
        .collect::<Vec<_>>())
}

/// The job, done by the first usable backend (or the one asked for).
pub fn list(wanted: Option<&str>) -> Result<Value, OpError> {
    let backend = BACKENDS
        .iter()
        .find(|b| wanted.map_or(true, |w| w == b.name()) && b.available())
        .ok_or_else(|| OpError::new("unavailable", "No disk backend works on this host"))?;
    Ok(json!({ "backend": backend.name(), "disks": backend.list()? }))
}
