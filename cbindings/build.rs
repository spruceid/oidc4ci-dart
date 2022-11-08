extern crate cbindgen;

use std::env;
use std::path::Path;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let lib_dir = Path::new(&crate_dir).parent().unwrap();
    let out_dir = lib_dir.join("target");
    let out_file = out_dir.join("oidc4ci.h");

    cbindgen::generate(lib_dir)
        .expect("Unable to generate bindings")
        .write_to_file(&out_file);

    println!("cargo:rerun-if-changed={:?}", &out_file);
}
