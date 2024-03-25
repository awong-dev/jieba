use jieba_rs::{Jieba, TokenizeMode, Error as JiebaError};
use rustler::{Env, Error as RustlerError, NifStruct, NifUnitEnum, ResourceArc, Term};
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

#[derive(NifUnitEnum)]
enum TokenizeEnum {
   Default,
   Search,
}

pub struct JiebaResource {
    jieba_rs: Mutex<Jieba>,
}

#[derive(NifStruct)]
#[module = "RustJieba"]
struct RustJieba {
    pub use_default: bool,
    pub dict_paths: Vec<String>,
    pub native: ResourceArc<JiebaResource>
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
fn io_error_to_rustler_error(err: IoError) -> RustlerError {
    let atom = match err.kind() {
        IoErrorKind::NotFound => atoms::enoent(),
        IoErrorKind::PermissionDenied => atoms::eacces(),
        IoErrorKind::BrokenPipe => atoms::epipe(),
        IoErrorKind::AlreadyExists => atoms::eexist(),
        _ => atoms::io_unknown(),
    };
    RustlerError::Term(Box::new(atom))
}

fn jieba_error_to_rustler_error(jieba_err: JiebaError) -> RustlerError {
    match jieba_err {
        JiebaError::Io(io_err) => io_error_to_rustler_error(io_err),
        JiebaError::InvalidDictEntry(entry) => RustlerError::Term(Box::new(entry))
    }
}

#[rustler::nif]
fn native_new() -> RustJieba {
    RustJieba {
        use_default: true,
        dict_paths: Vec::new(),
        native: ResourceArc::new(JiebaResource {
            jieba_rs: Mutex::new(Jieba::new()),
        })
    }
}

#[rustler::nif]
fn empty() -> RustJieba {
    RustJieba {
        use_default: false,
        dict_paths: Vec::new(),
        native: ResourceArc::new(JiebaResource {
            jieba_rs: Mutex::new(Jieba::empty()),
        })
    }
}

#[rustler::nif]
fn with_dict(dict_path: String) -> Result<RustJieba, RustlerError> {
    let file = File::open(&dict_path).map_err(io_error_to_rustler_error)?;
    let mut reader = BufReader::new(file);
    let jieba_rs = Jieba::with_dict(&mut reader).map_err(jieba_error_to_rustler_error)?;
    Ok(RustJieba {
        use_default: false,
        dict_paths: [dict_path].to_vec(),
        native: ResourceArc::new(JiebaResource {
            jieba_rs: Mutex::new(jieba_rs),
        })
    })
}

#[rustler::nif]
fn clone(jieba: RustJieba) -> RustJieba {
    let jieba_rs = jieba.native.jieba_rs.lock().unwrap();
    RustJieba {
        use_default: jieba.use_default,
        dict_paths: jieba.dict_paths.clone(),
        native: ResourceArc::new(JiebaResource {
            jieba_rs: Mutex::new(jieba_rs.clone())
        })
    }
}

#[rustler::nif]
fn load_dict(in_jieba: RustJieba, dict_path: String) -> Result<RustJieba, RustlerError> {
    let file = File::open(&dict_path).map_err(io_error_to_rustler_error)?;
    let mut jieba = in_jieba;
    {
        let jieba_rs = &mut jieba.native.jieba_rs.lock().unwrap();
        let mut reader = BufReader::new(file);
        jieba_rs.load_dict(&mut reader).map_err(jieba_error_to_rustler_error)?;
        jieba.dict_paths.push(dict_path);
    }
    Ok(jieba)
}

#[rustler::nif]
fn suggest_freq(jieba: RustJieba, segment: String) -> usize {
    jieba.native.jieba_rs.lock().unwrap()
        .suggest_freq(&segment)
}

#[rustler::nif]
fn add_word(jieba: RustJieba, word: String, freq: Option<usize>, new_tag: Option<&str>) -> usize {
    jieba.native.jieba_rs.lock().unwrap()
        .add_word(&word, freq, new_tag)
}

#[rustler::nif]
fn cut(jieba: RustJieba, sentence: String, hmm: bool) -> Vec<String> {
    jieba.native.jieba_rs.lock().unwrap()
        .cut(&sentence, hmm).into_iter().map(|s| s.to_string()).collect()
}

#[rustler::nif]
fn cut_all(jieba: RustJieba, sentence: String) -> Vec<String> {
    jieba.native.jieba_rs.lock().unwrap()
        .cut_all(&sentence).into_iter().map(|s| s.to_string()).collect()
}

#[rustler::nif]
fn cut_for_search(jieba: RustJieba, sentence: String, hmm: bool) -> Vec<String> {
    jieba.native.jieba_rs.lock().unwrap()
        .cut_for_search(&sentence, hmm).into_iter().map(|s| s.to_string()).collect()
}

#[rustler::nif]
fn tokenize(jieba: RustJieba, sentence: String, mode: TokenizeEnum, hmm: bool) -> Vec<JiebaToken> {
    jieba.native.jieba_rs.lock().unwrap()
        .tokenize(&sentence,
                   match mode {
                     TokenizeEnum::Default => TokenizeMode::Default,
                     TokenizeEnum::Search => TokenizeMode::Search
                   },
                   hmm)
        .into_iter()
        .map(|t| JiebaToken{ word: t.word.to_string(), start: t.start } )
        .collect()
}

#[rustler::nif]
fn tag(jieba: RustJieba, sentence: String, hmm: bool) -> Vec<JiebaTag> {
    jieba.native.jieba_rs.lock().unwrap()
        .tag(&sentence, hmm)
        .into_iter()
        .map(|t| JiebaTag{ word: t.word.to_string(), tag: t.tag.to_string() })
        .collect()
}

rustler::init!(
    "Elixir.RustJieba",
    [native_new, empty, with_dict, clone, load_dict, suggest_freq, add_word, cut, cut_all,
     cut_for_search, tokenize, tag],
    load = on_load);
