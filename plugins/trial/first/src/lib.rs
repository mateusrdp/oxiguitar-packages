// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors

//! A plugin that does nothing but load: an effect that passes the sound
//! through. It exists so that plugin-release.yml can be tried on a real
//! `.oxp` file. Never shipped.

use oxiguitar_plugin::audio::PrepareEffect;
use oxiguitar_plugin::{Effect, Error, Host, Plugin, Processor};

/// The plugin.
#[derive(Debug)]
pub struct Trial;

impl Plugin for Trial {
    fn start(_host: Host) -> Result<Trial, Error> {
        Ok(Trial)
    }

    fn effect(&self, id: &str) -> Option<&dyn Effect> {
        (id == "pass").then_some(self as &dyn Effect)
    }
}

impl Effect for Trial {
    fn prepare(&self, _prepare: &PrepareEffect) -> Result<Box<dyn Processor>, Error> {
        Ok(Box::new(Pass))
    }
}

struct Pass;

impl Processor for Pass {
    fn process(&mut self, _left: &mut [f32], _right: &mut [f32]) {}
}

oxiguitar_plugin::export_plugin!(Trial);

#[cfg(test)]
mod tests {
    #[test]
    fn the_manifest_is_valid_for_the_plugin() {
        let problems = oxiguitar_plugin::check::<super::Trial>(
            include_str!("../manifest.json"),
            env!("CARGO_PKG_VERSION"),
        );
        assert!(problems.is_empty(), "{}", problems.join("; "));
    }
}
