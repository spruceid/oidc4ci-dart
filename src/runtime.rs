use tokio::runtime::{Builder, Runtime};

use crate::error::Error;

pub fn get() -> Result<Runtime, Error> {
    let rt = Builder::new_current_thread().enable_all().build()?;
    Ok(rt)
}
