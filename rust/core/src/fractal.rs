//! The Mandelbrot set as RGBA pixels. Natively it shares bands of rows
//! across every CPU; wasm on the web is single-threaded, so it draws in one
//! pass there.

use serde::Deserialize;

#[derive(Deserialize)]
pub struct View {
    pub width: u32,
    pub height: u32,
    /// The centre of the view in the complex plane.
    pub x: f64,
    pub y: f64,
    /// The width of the view in the complex plane.
    pub scale: f64,
    #[serde(default = "four_hundred")]
    pub iterations: u32,
}

fn four_hundred() -> u32 {
    400
}

/// Caps a render at 16 megapixels, so a bad request cannot exhaust memory.
const MAX_PIXELS: usize = 16 << 20;

pub fn render(view: &View) -> Vec<u8> {
    let width = view.width.max(1) as usize;
    let height = (view.height.max(1) as usize).min(MAX_PIXELS / width).max(1);
    let iterations = view.iterations.clamp(1, 5000);
    let mut pixels = vec![0u8; width * height * 4];
    let step = view.scale / width as f64;
    let top = view.y - step * height as f64 / 2.0;
    let left = view.x - view.scale / 2.0;
    // Rows inside the set cost `iterations` each, so hand out small bands on
    // demand instead of one fixed block per thread.
    const BAND_ROWS: usize = 8;
    let draw = |band: usize, chunk: &mut [u8]| {
        for (i, pixel) in chunk.chunks_exact_mut(4).enumerate() {
            let x = i % width;
            let y = band * BAND_ROWS + i / width;
            let c = (left + x as f64 * step, top + y as f64 * step);
            pixel.copy_from_slice(&colour(escape(c, iterations), iterations));
        }
    };
    #[cfg(not(target_family = "wasm"))]
    {
        let bands = std::sync::Mutex::new(pixels.chunks_mut(BAND_ROWS * width * 4).enumerate());
        let threads = std::thread::available_parallelism().map_or(1, |n| n.get());
        std::thread::scope(|scope| {
            for _ in 0..threads {
                scope.spawn(|| loop {
                    let Some((band, chunk)) = bands.lock().unwrap().next() else { break };
                    draw(band, chunk);
                });
            }
        });
    }
    #[cfg(target_family = "wasm")]
    for (band, chunk) in pixels.chunks_mut(BAND_ROWS * width * 4).enumerate() {
        draw(band, chunk);
    }
    pixels
}

/// Smooth escape count, or None inside the set.
fn escape((cr, ci): (f64, f64), iterations: u32) -> Option<f64> {
    // Points in the main cardioid or the period-2 bulb never escape; skip
    // their full iteration count.
    let q = (cr - 0.25) * (cr - 0.25) + ci * ci;
    if q * (q + (cr - 0.25)) <= 0.25 * ci * ci || (cr + 1.0) * (cr + 1.0) + ci * ci <= 0.0625 {
        return None;
    }
    let (mut zr, mut zi) = (0.0f64, 0.0f64);
    for n in 0..iterations {
        let (zr2, zi2) = (zr * zr, zi * zi);
        if zr2 + zi2 > 256.0 {
            return Some(n as f64 + 1.0 - ((zr2 + zi2).ln() / 2.0).ln() / std::f64::consts::LN_2);
        }
        zi = 2.0 * zr * zi + ci;
        zr = zr2 - zi2 + cr;
    }
    None
}

fn colour(escape: Option<f64>, iterations: u32) -> [u8; 4] {
    let Some(n) = escape else { return [8, 12, 16, 255] };
    let t = (n / iterations as f64).sqrt();
    let wave = |phase: f64| ((0.5 + 0.5 * (6.283 * (t * 3.0 + phase)).cos()) * 255.0) as u8;
    [wave(0.0), wave(0.15), wave(0.3), 255]
}
