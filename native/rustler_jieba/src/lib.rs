use jieba_rs::{Jieba, TokenizeMode, Error as JiebaError};
use rustler::{Atom, Encoder, Env, Error as RustlerError, NifStruct, ResourceArc, Term};
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

#[derive(NifStruct)]
#[module = "RustJieba.Token"]
struct JiebaToken {
    pub word: String,
    pub start: usize,
}

#[derive(NifStruct)]
#[module = "RustJieba.Tag"]
struct JiebaTag {
    pub word: String,
    pub tag: String,
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
fn new() -> ResourceArc<JiebaResource> {
    ResourceArc::new(JiebaResource {
        jieba: Mutex::new(Jieba::new()),
    })
}

#[rustler::nif]
fn empty() -> ResourceArc<JiebaResource> {
    ResourceArc::new(JiebaResource {
        jieba: Mutex::new(Jieba::empty()),
    })
}

#[rustler::nif]
fn with_dict(dict_path: String) -> ResourceArc<JiebaResource> {
    match File::open(dict_path) {
        Ok(f) => {
            let mut reader = BufReader::new(f);
            match Jieba::with_dict(&mut reader) {
                Ok(jieba) => ResourceArc::new(JiebaResource {
                    jieba: Mutex::new(jieba),
                }),
                _ => ResourceArc::new(JiebaResource { jieba: Mutex::new(Jieba::empty()) })
            }
        },
        Err(ref _io_err) => ResourceArc::new(JiebaResource { jieba: Mutex::new(Jieba::empty()) })
    }
}

#[rustler::nif]
fn clone(resource: ResourceArc<JiebaResource>) -> ResourceArc<JiebaResource> {
    let ref jieba = *resource.jieba.lock().unwrap();
    ResourceArc::new(JiebaResource { jieba: Mutex::new(jieba.clone()) })
}

#[rustler::nif]
fn load_dict(env: Env, resource: ResourceArc<JiebaResource>, dict_path: String) -> Result<Term, RustlerError> {
    match File::open(dict_path) {
        Ok(f) => {
            let jieba = &mut *resource.jieba.lock().unwrap();
            let mut reader = BufReader::new(f);
            match jieba.load_dict(&mut reader) {
                Ok(()) => Ok(resource.encode(env)),
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
fn suggest_freq(resource: ResourceArc<JiebaResource>, segment: String) -> usize {
    let ref jieba= *resource.jieba.lock().unwrap();
    jieba.suggest_freq(&segment)
}

#[rustler::nif]
fn add_word(resource: ResourceArc<JiebaResource>, word: String, freq: Option<usize>, new_tag: Option<&str>) -> usize {
    let ref mut jieba= *resource.jieba.lock().unwrap();
    jieba.add_word(&word, freq, new_tag)
}

#[rustler::nif]
fn cut(resource: ResourceArc<JiebaResource>, sentence: String, hmm: bool) -> Vec<String> {
    let ref jieba= *resource.jieba.lock().unwrap();
    jieba.cut(&sentence, hmm).into_iter().map(|s| s.to_string()).collect()
}

#[rustler::nif]
fn cut_all(resource: ResourceArc<JiebaResource>, sentence: String) -> Vec<String> {
    let ref jieba= *resource.jieba.lock().unwrap();
    jieba.cut_all(&sentence).into_iter().map(|s| s.to_string()).collect()
}

#[rustler::nif]
fn cut_for_search(resource: ResourceArc<JiebaResource>, sentence: String, hmm: bool) -> Vec<String> {
    let ref jieba= *resource.jieba.lock().unwrap();
    jieba.cut_for_search(&sentence, hmm).into_iter().map(|s| s.to_string()).collect()
}

#[rustler::nif]
fn tokenize(resource: ResourceArc<JiebaResource>, sentence: String, mode: String, hmm: bool) -> Vec<JiebaToken> {
    let ref jieba= *resource.jieba.lock().unwrap();
    jieba.tokenize(&sentence,
                   if mode == "search" { TokenizeMode::Search } else { TokenizeMode::Default },
                   hmm)
        .into_iter()
        .map(|t| JiebaToken{ word: t.word.to_string(), start: t.start } )
        .collect()
}

#[rustler::nif]
fn tag(resource: ResourceArc<JiebaResource>, sentence: String, hmm: bool) -> Vec<JiebaTag> {
    let ref jieba= *resource.jieba.lock().unwrap();
    jieba.tag(&sentence, hmm)
        .into_iter()
        .map(|t| JiebaTag{ word: t.word.to_string(), tag: t.tag.to_string() })
        .collect()
}

rustler::init!(
    "Elixir.RustJieba",
    [new, empty, with_dict, clone, load_dict, suggest_freq, add_word, cut, cut_all,
     cut_for_search, tokenize, tag],
    load = on_load);
