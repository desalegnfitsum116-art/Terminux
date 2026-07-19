pub fn terminux_version() -> &'static str {
    // See build.rs
    env!("TERMINUX_CI_TAG")
}

pub fn terminux_target_triple() -> &'static str {
    // See build.rs
    env!("TERMINUX_TARGET_TRIPLE")
}
