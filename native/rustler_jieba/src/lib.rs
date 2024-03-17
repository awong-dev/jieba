use jieba_rs::{Jieba, Error as JiebaError};
use rustler::{Atom, Env, Error as RustlerError, ResourceArc, Term};
use std::fs::File;
use std::io::BufReader;
use std::sync::Mutex;
use std::io::Error as IoError;
use std::io::ErrorKind as IoErrorKind;

// Creates an atoms module using the rustler macro
mod atoms {
    rustler::atoms! {
        ok,
        invalidentry,

        // Posix
        enoent, // File does not exist
        eacces, // Permission denied
        epipe, // Broken pipe
        eexist, // File exists

        io_unknown // Other error
    }
}

pub struct JiebaResource {
    jieba: Mutex<Jieba>,
}

fn on_load(env: Env, _term: Term) -> bool {
    rustler::resource!(JiebaResource, env);
    true
}

// Translates std library errors into Rustler atoms
fn io_error_to_term(err: &IoError) -> Atom {
    match err.kind() {
        IoErrorKind::NotFound => atoms::enoent(),
        IoErrorKind::PermissionDenied => atoms::eacces(),
        IoErrorKind::BrokenPipe => atoms::epipe(),
        IoErrorKind::AlreadyExists => atoms::eexist(),
        _ => atoms::io_unknown(),
    }
}

#[rustler::nif]
fn make(use_default: bool) -> ResourceArc<JiebaResource> {
    let jieba = if use_default { Jieba::new() } else { Jieba::empty() };
    ResourceArc::new(JiebaResource {
        jieba: Mutex::new(jieba),
    })
}

#[rustler::nif]
fn load_dict(env: Env, resource: ResourceArc<JiebaResource>, dict_path: String) -> Result<Term, RustlerError> {
    match File::open(dict_path) {
        Ok(f) => {
            let jieba = &mut *resource.jieba.lock().unwrap();
            let mut reader = BufReader::new(f);
            match jieba.load_dict(&mut reader) {
                Ok(()) => Ok(atoms::ok().to_term(env)),
                    Err(jieba_err) => match jieba_err {
                        JiebaError::Io(ref io_err) => Err(RustlerError::Term(Box::new(io_error_to_term(io_err)))),
                        JiebaError::InvalidDictEntry(entry) => Err(RustlerError::Term(Box::new(entry)))
                    }
            }
        },
            Err(ref io_err) => Err(RustlerError::Term(Box::new(io_error_to_term(io_err))))
    }
}

#[rustler::nif]
fn cut(resource: ResourceArc<JiebaResource>, text: String) -> Vec<String> {
    let ref jieba= *resource.jieba.lock().unwrap();
    jieba.cut(&text, true).into_iter().map(|s| s.to_string()).collect()
}

rustler::init!("Elixir.Jieba", [make, load_dict, cut], load = on_load);
