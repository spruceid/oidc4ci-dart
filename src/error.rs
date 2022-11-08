use std::cell::BorrowError;
use std::ffi::CString;
use std::ffi::NulError;
use std::fmt;
use std::os::raw::{c_char, c_int};
use std::ptr;

use serde_json::Error as JSONError;
use std::error::Error as StdError;
use std::io::Error as IOError;
use std::str::Utf8Error;

static UNKNOWN_ERROR: &str = "Unable to create error string\0";

use std::cell::RefCell;
thread_local! {
    pub static LAST_ERROR: RefCell<Option<(i32, CString)>> = RefCell::new(None);
}

#[derive(Debug)]
#[non_exhaustive]
pub enum Error {
    //DIDKit(didkit::error::Error),
    JSON(JSONError),
    SSIJWK(ssi::jwk::Error),
    SSIJWS(ssi::jws::Error),
    Null(NulError),
    Utf8(Utf8Error),
    Borrow(BorrowError),
    IO(IOError),
    UnableToGenerateDID,
    UnknownDIDMethod,
    UnableToGetVerificationMethod,
    UnknownProofFormat(String),
}

impl Error {
    pub fn stash(self) {
        LAST_ERROR.with(|stash| {
            stash.replace(Some((
                self.get_code(),
                CString::new(self.to_string()).unwrap(),
            )))
        });
    }

    fn get_code(&self) -> c_int {
        // TODO: try to give each individual error its own number
        match self {
            Error::JSON(_) => 1,
            Error::SSIJWK(_) => 1,
            Error::SSIJWS(_) => 1,
            Error::Null(_) => 2,
            Error::Utf8(_) => 3,
            _ => -1,
        }
    }
}

impl StdError for Error {}

#[no_mangle]
/// Retrieve a human-readable description of the most recent error encountered by a DIDKit C
/// function. The returned string is valid until the next call to a DIDKit function in the current
/// thread, and should not be mutated or freed. If there has not been any error, `NULL` is returned.
pub extern "C" fn oidc4ci_error_message() -> *const c_char {
    LAST_ERROR.with(|error| match error.try_borrow() {
        Ok(maybe_err_ref) => match &*maybe_err_ref {
            Some(err) => err.1.as_ptr() as *const c_char,
            None => ptr::null(),
        },
        Err(_) => UNKNOWN_ERROR.as_ptr() as *const c_char,
    })
}

#[no_mangle]
/// Retrieve a numeric code for the most recent error encountered by a DIDKit C function. If there
/// has not been an error, 0 is returned.
pub extern "C" fn oidc4ci_error_code() -> c_int {
    LAST_ERROR.with(|error| match error.try_borrow() {
        Ok(maybe_err_ref) => match &*maybe_err_ref {
            Some(err) => err.0,
            None => 0,
        },
        Err(err) => Error::from(err).get_code(),
    })
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            //Error::DIDKit(e) => e.fmt(f),
            Error::JSON(e) => e.fmt(f),
            Error::SSIJWK(e) => e.fmt(f),
            Error::SSIJWS(e) => e.fmt(f),
            Error::Null(e) => e.fmt(f),
            Error::Utf8(e) => e.fmt(f),
            Error::UnableToGenerateDID => write!(f, "Unable to generate DID"),
            Error::UnknownDIDMethod => write!(f, "Unknown DID method"),
            Error::UnableToGetVerificationMethod => write!(f, "Unable to get verification method"),
            Error::UnknownProofFormat(format) => write!(f, "Unknown proof format: {}", format),
            _ => unreachable!(),
        }
    }
}

// impl From<didkit::error::Error> for Error {
//     fn from(err: didkit::error::Error) -> Error {
//         Error::DIDKit(err)
//     }
// }

impl From<JSONError> for Error {
    fn from(err: JSONError) -> Error {
        Error::JSON(err)
    }
}

impl From<ssi::jwk::Error> for Error {
    fn from(err: ssi::jwk::Error) -> Error {
        Error::SSIJWK(err)
    }
}

impl From<ssi::jws::Error> for Error {
    fn from(err: ssi::jws::Error) -> Error {
        Error::SSIJWS(err)
    }
}

impl From<NulError> for Error {
    fn from(err: NulError) -> Error {
        Error::Null(err)
    }
}

impl From<Utf8Error> for Error {
    fn from(err: Utf8Error) -> Error {
        Error::Utf8(err)
    }
}

impl From<IOError> for Error {
    fn from(err: IOError) -> Error {
        Error::IO(err)
    }
}

impl From<BorrowError> for Error {
    fn from(err: BorrowError) -> Error {
        Error::Borrow(err)
    }
}
