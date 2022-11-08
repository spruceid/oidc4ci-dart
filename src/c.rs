use std::ffi::CStr;
use std::ffi::CString;
use std::os::raw::c_char;
use std::ptr;

use oidc4vci_rs::CredentialFormat;
use oidc4vci_rs::SSI;

use crate::error::*;

pub static VERSION_C: &str = concat!(env!("CARGO_PKG_VERSION"), "\0");

#[no_mangle]
pub extern "C" fn oidc4ci_get_version() -> *const c_char {
    VERSION_C.as_ptr() as *const c_char
}

fn ccchar_or_error(result: Result<*const c_char, Error>) -> *const c_char {
    match result {
        Ok(ccchar) => ccchar,
        Err(error) => {
            error.stash();
            ptr::null()
        }
    }
}

#[no_mangle]
pub extern "C" fn oidc4ci_free_string(string: *const c_char) {
    if string.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(string as *mut c_char));
    }
}

/* OIDC4CI */

fn generate_token_request(params_ptr: *const c_char) -> Result<*const c_char, Error> {
    let params_str = unsafe { CStr::from_ptr(params_ptr) }.to_str()?;
    let params = serde_json::from_str(params_str)?;
    let token_request = oidc4vci_rs::generate_token_request(params);
    Ok(CString::new(token_request)?.into_raw())
}

#[no_mangle]
pub extern "C" fn oidc4ci_generate_token_request(params: *const c_char) -> *const c_char {
    ccchar_or_error(generate_token_request(params))
}

fn generate_credential_request(
    ty_ptr: *const c_char,
    format_ptr: *const c_char,
    issuer_ptr: *const c_char,
    audience_ptr: *const c_char,
    jwk_ptr: *const c_char,
    alg_ptr: *const c_char,
) -> Result<*const c_char, Error> {
    let ty = unsafe { CStr::from_ptr(ty_ptr) }.to_str()?;

    let format_str = unsafe { CStr::from_ptr(format_ptr) }.to_str()?;
    let format: CredentialFormat = serde_json::from_str(&format!("\"{}\"", format_str))?;

    let issuer = unsafe { CStr::from_ptr(issuer_ptr) }.to_str()?;
    let audience = unsafe { CStr::from_ptr(audience_ptr) }.to_str()?;

    let jwk_str = unsafe { CStr::from_ptr(jwk_ptr) }.to_str()?;
    let jwk = serde_json::from_str(jwk_str)?;

    let alg_str = unsafe { CStr::from_ptr(alg_ptr) }.to_str()?;
    let alg = serde_json::from_str(&format!("\"{}\"", alg_str))?;

    let interface = SSI::new(jwk, alg, "");
    let proof_of_possesion =
        oidc4vci_rs::generate_proof_of_possession(issuer, audience, &interface)
            .map_err(|_| crate::error::Error::UnknownDIDMethod)?;
    let credential_request =
        oidc4vci_rs::generate_credential_request(ty, format, proof_of_possesion);
    let credential_request_str = serde_json::to_string(&credential_request)?;

    Ok(CString::new(credential_request_str)?.into_raw())
}

#[no_mangle]
pub extern "C" fn oidc4ci_generate_credential_request(
    ty: *const c_char,
    format: *const c_char,
    issuer: *const c_char,
    audience: *const c_char,
    jwk: *const c_char,
    alg: *const c_char,
) -> *const c_char {
    ccchar_or_error(generate_credential_request(
        ty, format, issuer, audience, jwk, alg,
    ))
}
