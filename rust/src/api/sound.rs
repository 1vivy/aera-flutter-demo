//! AERA's speaker, which only the AERA build has: notes played by Rust
//! through aera-sdk over one lasting connection to AERA's audio bridge.
//! Other hosts answer with an error and the Sound page says so.

/// Plays notes one after another as a single stream, so they never overlap.
pub fn play_notes(frequencies_hz: Vec<f32>, note_milliseconds: u32, volume: f32) -> Result<(), String> {
    #[cfg(target_os = "linux")]
    {
        let mut samples = Vec::new();
        for frequency in frequencies_hz {
            let mut note = aera_sdk::audio::tone(frequency, note_milliseconds, volume);
            fade(&mut note);
            samples.extend(note);
        }
        aera_sdk::speaker::Speaker::global().play_checked(samples)
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = (frequencies_hz, note_milliseconds, volume);
        Err("AERA's speaker is only there inside AERA Recovery".into())
    }
}

/// Ramps the ends of a stereo note to avoid clicks.
#[cfg(target_os = "linux")]
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
