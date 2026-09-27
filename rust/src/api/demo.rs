//! Rust that only the demo uses.

/// Renders the Mandelbrot set as RGBA pixels, splitting rows across all CPUs.
/// `scale` is the width of the view in the complex plane.
pub fn mandelbrot(
    width: u32,
    height: u32,
    center_x: f64,
    center_y: f64,
    scale: f64,
    max_iterations: u32,
) -> Vec<u8> {
    let (width, height) = (width.max(1) as usize, height.max(1) as usize);
    let mut pixels = vec![0u8; width * height * 4];
    let step = scale / width as f64;
    let top = center_y - step * height as f64 / 2.0;
    let left = center_x - scale / 2.0;
    let threads = std::thread::available_parallelism().map_or(1, |n| n.get());
    let rows_per_chunk = height.div_ceil(threads);
    std::thread::scope(|scope| {
        for (chunk_index, chunk) in pixels.chunks_mut(rows_per_chunk * width * 4).enumerate() {
            scope.spawn(move || {
                for (i, pixel) in chunk.chunks_exact_mut(4).enumerate() {
                    let x = i % width;
                    let y = chunk_index * rows_per_chunk + i / width;
                    let c = (left + x as f64 * step, top + y as f64 * step);
                    pixel.copy_from_slice(&colour(escape(c, max_iterations), max_iterations));
                }
            });
        }
    });
    pixels
}

/// Smooth escape count, or None inside the set.
fn escape((cr, ci): (f64, f64), max_iterations: u32) -> Option<f64> {
    let (mut zr, mut zi) = (0.0f64, 0.0f64);
    for n in 0..max_iterations {
        let (zr2, zi2) = (zr * zr, zi * zi);
        if zr2 + zi2 > 256.0 {
            return Some(n as f64 + 1.0 - ((zr2 + zi2).ln() / 2.0).ln() / std::f64::consts::LN_2);
        }
        zi = 2.0 * zr * zi + ci;
        zr = zr2 - zi2 + cr;
    }
    None
}

fn colour(escape: Option<f64>, max_iterations: u32) -> [u8; 4] {
    let Some(n) = escape else { return [8, 12, 16, 255] };
    let t = (n / max_iterations as f64).sqrt();
    let wave = |phase: f64| ((0.5 + 0.5 * (6.283 * (t * 3.0 + phase)).cos()) * 255.0) as u8;
    [wave(0.0), wave(0.15), wave(0.3), 255]
}

/// Plays notes one after another as a single stream, so they never overlap.
pub fn play_notes(frequencies_hz: Vec<f32>, note_milliseconds: u32, volume: f32) -> anyhow::Result<()> {
    let mut samples = Vec::new();
    for frequency in frequencies_hz {
        let mut note = aera_sdk::audio::tone(frequency, note_milliseconds, volume);
        fade(&mut note);
        samples.extend(note);
    }
    let mut output = aera_sdk::audio::AudioOutput::connect()?;
    output.write(&samples)?;
    Ok(())
}

/// Ramps the ends of a stereo note to avoid clicks.
fn fade(samples: &mut [i16]) {
    let frames = samples.len() / 2;
    let ramp = (aera_sdk::audio::SAMPLE_RATE as usize / 200).min(frames / 2);
    for i in 0..ramp {
        let gain = i as f32 / ramp as f32;
        for index in [i, frames - 1 - i] {
            for channel in 0..2 {
                let sample = &mut samples[index * 2 + channel];
                *sample = (*sample as f32 * gain) as i16;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn origin_is_inside_the_set() {
        let pixels = super::mandelbrot(3, 3, 0.0, 0.0, 0.01, 100);
        assert_eq!(&pixels[16..20], &[8, 12, 16, 255]);
        assert_eq!(pixels.len(), 36);
    }
}
